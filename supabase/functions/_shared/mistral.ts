/**
 * Minimal Mistral API client for Edge Functions. The API key is read from
 * `Deno.env` — a function secret set via `supabase secrets set
 * MISTRAL_API_KEY=...` — and is never accepted from, or echoed back to,
 * the client. This file is the ONLY place in the codebase allowed to touch
 * that key.
 */

const MISTRAL_API_BASE = "https://api.mistral.ai/v1";

export interface MistralMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface ChatCompletionOptions {
  model?: string;
  messages: MistralMessage[];
  temperature?: number;
  maxTokens?: number;
  /** When set, Mistral returns JSON matching the given schema shape. */
  responseFormat?: { type: "json_object" };
}

function apiKey(): string {
  const key = Deno.env.get("MISTRAL_API_KEY");
  if (!key) {
    throw new Error(
      "MISTRAL_API_KEY is not configured. Set it with `supabase secrets set MISTRAL_API_KEY=...`.",
    );
  }
  return key;
}

/** Streams a chat completion as raw SSE bytes, passed straight through to the client. */
export async function streamChatCompletion(
  options: ChatCompletionOptions,
): Promise<Response> {
  const response = await fetch(`${MISTRAL_API_BASE}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey()}`,
    },
    body: JSON.stringify({
      model: options.model ?? "mistral-large-latest",
      messages: options.messages,
      temperature: options.temperature ?? 0.7,
      max_tokens: options.maxTokens ?? 1024,
      stream: true,
    }),
  });

  if (!response.ok || !response.body) {
    const errorText = await response.text();
    throw new Error(`Mistral API error (${response.status}): ${errorText}`);
  }

  return response;
}

/** Non-streaming call used for structured JSON outputs (meal analysis, daily plan, workout gen). */
export async function completeStructured<T>(
  options: ChatCompletionOptions,
): Promise<T> {
  const response = await fetch(`${MISTRAL_API_BASE}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey()}`,
    },
    body: JSON.stringify({
      model: options.model ?? "mistral-large-latest",
      messages: options.messages,
      temperature: options.temperature ?? 0.3,
      max_tokens: options.maxTokens ?? 1024,
      response_format: options.responseFormat ?? { type: "json_object" },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Mistral API error (${response.status}): ${errorText}`);
  }

  const json = await response.json();
  const content = json.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("Mistral returned no content");
  }
  return JSON.parse(content) as T;
}

/** Vision-capable model for meal photo analysis. `imageBase64` is a data URL or raw base64 JPEG/PNG. */
export async function completeVisionStructured<T>(params: {
  systemPrompt: string;
  userPrompt: string;
  imageBase64: string;
}): Promise<T> {
  const imageUrl = params.imageBase64.startsWith("data:")
    ? params.imageBase64
    : `data:image/jpeg;base64,${params.imageBase64}`;

  const response = await fetch(`${MISTRAL_API_BASE}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey()}`,
    },
    body: JSON.stringify({
      model: "pixtral-large-latest",
      messages: [
        { role: "system", content: params.systemPrompt },
        {
          role: "user",
          content: [
            { type: "text", text: params.userPrompt },
            { type: "image_url", image_url: imageUrl },
          ],
        },
      ],
      temperature: 0.2,
      max_tokens: 1024,
      response_format: { type: "json_object" },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Mistral vision API error (${response.status}): ${errorText}`);
  }

  const json = await response.json();
  const content = json.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("Mistral returned no content");
  }
  return JSON.parse(content) as T;
}
