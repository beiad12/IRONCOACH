// Meal Analysis Edge Function
//
// Given a base64 meal photo (and optional text description), returns a
// structured nutrition estimate via Mistral's vision model, and — if
// `mealEntryId` is provided — writes the result onto that meal_entries row
// so the client can simply re-fetch rather than parse the response itself.
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { buildRequestContext } from "../_shared/supabase_ctx.ts";
import { completeVisionStructured } from "../_shared/mistral.ts";
import { AGENT_SYSTEM_PROMPTS } from "../_shared/agents.ts";

interface MealAnalysisResult {
  foodName: string;
  estimatedCalories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  confidence: "low" | "medium" | "high";
  notes: string;
}

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { userId, adminClient } = await buildRequestContext(req);
    const { imageBase64, description, mealEntryId } = await req.json();

    if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
      return json({ error: "`imageBase64` is required" }, 400);
    }

    const result = await completeVisionStructured<MealAnalysisResult>({
      systemPrompt: AGENT_SYSTEM_PROMPTS.meal_analysis,
      userPrompt: description
        ? `Analyze this meal photo. Additional context from the user: "${description}"`
        : "Analyze this meal photo and estimate its nutritional content.",
      imageBase64,
    });

    if (typeof mealEntryId === "string") {
      const { error } = await adminClient
        .from("meal_entries")
        .update({ ai_analysis: result })
        .eq("id", mealEntryId)
        .eq("user_id", userId);
      if (error) throw new Error(error.message);
    }

    return json({ result }, 200);
  } catch (err) {
    if (err instanceof Response) return err;
    console.error("meal-analysis error", err);
    return json({ error: "Failed to analyze meal photo" }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
