// Daily Planner Edge Function
//
// Pulls the caller's recent training, nutrition, and profile data, asks
// Mistral for a single structured day-plan (workout focus, nutrition
// targets, one recovery tip), and stores it as an `ai_insights` row so it
// surfaces through the existing notifications/insights feed.
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { buildRequestContext } from "../_shared/supabase_ctx.ts";
import { completeStructured } from "../_shared/mistral.ts";
import { AGENT_SYSTEM_PROMPTS } from "../_shared/agents.ts";

interface DailyPlanResult {
  summary: string;
  workoutSuggestion: {
    focus: string;
    durationMinutes: number;
    exercises: string[];
  };
  nutritionTargets: {
    calories: number;
    proteinG: number;
    carbsG: number;
    fatG: number;
    waterMl: number;
  };
  recoveryTip: string;
}

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { userId, adminClient } = await buildRequestContext(req);

    const [{ data: profile }, { data: recentSessions }, { data: recentMeals }, { data: goals }] =
      await Promise.all([
        adminClient.from("profiles").select(
          "fitness_level, primary_goal, weight_kg, height_cm",
        ).eq("id", userId).single(),
        adminClient.from("workout_sessions").select("name, started_at, total_volume_kg")
          .eq("user_id", userId).order("started_at", { ascending: false }).limit(5),
        adminClient.from("meal_entries").select("meal_type, logged_at")
          .eq("user_id", userId).order("logged_at", { ascending: false }).limit(10),
        adminClient.from("nutrition_goals").select("*").eq("user_id", userId).maybeSingle(),
      ]);

    const contextPrompt = JSON.stringify({
      profile,
      recentSessions,
      recentMeals,
      currentGoals: goals,
    });

    const plan = await completeStructured<DailyPlanResult>({
      messages: [
        { role: "system", content: AGENT_SYSTEM_PROMPTS.daily_planner },
        {
          role: "user",
          content:
            "Here is my profile and recent activity as JSON. Generate today's plan.\n\n" +
            contextPrompt,
        },
      ],
    });

    const { error: insightError } = await adminClient.from("ai_insights").insert({
      user_id: userId,
      agent_type: "daily_planner",
      title: "Your plan for today",
      body: plan.summary,
      data: plan,
    });
    if (insightError) throw new Error(insightError.message);

    return json({ plan }, 200);
  } catch (err) {
    if (err instanceof Response) return err;
    console.error("daily-planner error", err);
    return json({ error: "Failed to generate today's plan" }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
