// AI Proxy Edge Function
//
// Streams a chat completion from Mistral for one of IronCoach's specialized
// coach agents, while keeping the Mistral API key entirely server-side.
// The Flutter client only ever talks to this function (via
// `supabase.functions.invoke`), never to api.mistral.ai directly.
//
// Request body:
//   { "agentType": "workout_coach", "message": "How should I progress squats?" }
//
// Behavior:
//   1. Verify the caller's Supabase JWT.
//   2. Load/create the (user, agentType) conversation and its last N
//      messages for context (conversation memory).
//   3. Persist the user's new message.
//   4. Stream the assistant's reply back to the client as Server-Sent
//      Events, forwarding Mistral's stream chunk-for-chunk.
//   5. Once the stream completes, persist the full assistant reply.
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { buildRequestContext } from "../_shared/supabase_ctx.ts";
import { streamChatCompletion } from "../_shared/mistral.ts";
import { AGENT_SYSTEM_PROMPTS, isAgentType } from "../_shared/agents.ts";

const HISTORY_LIMIT = 20;

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { userId, adminClient } = await buildRequestContext(req);
    const { agentType, message } = await req.json();

    if (typeof message !== "string" || message.trim().length === 0) {
      return json({ error: "`message` is required" }, 400);
    }
    if (typeof agentType !== "string" || !isAgentType(agentType)) {
      return json({ error: "`agentType` is invalid" }, 400);
    }

    const { data: conversation, error: convError } = await adminClient
      .from("ai_conversations")
      .upsert(
        { user_id: userId, agent_type: agentType },
        { onConflict: "user_id,agent_type", ignoreDuplicates: false },
      )
      .select()
      .single();

    if (convError) throw new Error(convError.message);

    const { data: history } = await adminClient
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversation.id)
      .order("created_at", { ascending: false })
      .limit(HISTORY_LIMIT);

    const orderedHistory = (history ?? []).reverse();

    await adminClient.from("ai_messages").insert({
      conversation_id: conversation.id,
      role: "user",
      content: message,
    });

    const mistralResponse = await streamChatCompletion({
      messages: [
        { role: "system", content: AGENT_SYSTEM_PROMPTS[agentType] },
        ...orderedHistory.map((m) => ({
          role: m.role as "user" | "assistant",
          content: m.content as string,
        })),
        { role: "user", content: message },
      ],
    });

    // Tee the upstream SSE stream: one branch goes straight to the client,
    // the other is buffered here so we can persist the full assistant
    // reply once the stream ends.
    const [clientStream, captureStream] = mistralResponse.body!.tee();
    captureAssistantReply(captureStream, adminClient, conversation.id);

    return new Response(clientStream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (err) {
    if (err instanceof Response) return err;
    console.error("ai-proxy error", err);
    return json({ error: "Internal error generating a response" }, 500);
  }
});

async function captureAssistantReply(
  stream: ReadableStream<Uint8Array>,
  // deno-lint-ignore no-explicit-any
  adminClient: any,
  conversationId: string,
) {
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let fullReply = "";

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = decoder.decode(value, { stream: true });
      for (const line of chunk.split("\n")) {
        if (!line.startsWith("data: ")) continue;
        const payload = line.slice(6).trim();
        if (payload === "[DONE]") continue;
        try {
          const parsed = JSON.parse(payload);
          const delta = parsed.choices?.[0]?.delta?.content;
          if (delta) fullReply += delta;
        } catch {
          // Ignore malformed/partial SSE chunks; the client-facing stream
          // is unaffected since this is a separate tee'd branch.
        }
      }
    }
  } finally {
    if (fullReply.trim().length > 0) {
      await adminClient.from("ai_messages").insert({
        conversation_id: conversationId,
        role: "assistant",
        content: fullReply,
      });
    }
  }
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
