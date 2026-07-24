# API — Edge Functions

All three functions require a valid Supabase user JWT
(`Authorization: Bearer <access_token>`) — there is no unauthenticated
path. The Mistral API key is a Supabase function secret
(`MISTRAL_API_KEY`), read only in `supabase/functions/_shared/mistral.ts`,
and is never returned in any response.

Base URL: `${SUPABASE_URL}/functions/v1/<function-name>`

## `POST /ai-proxy`

Streaming chat with one of the four conversational coach agents.

**Request**

```json
{
  "agentType": "workout_coach",
  "message": "How should I progress my squat this week?"
}
```

`agentType` ∈ `workout_coach | nutrition_coach | recovery_coach | motivation_coach`
(`meal_analysis` and `daily_planner` are valid system-prompt keys but are
only ever invoked through their own dedicated functions below, not through
`ai-proxy`.)

**Response**: `200`, `Content-Type: text/event-stream` — Mistral's chat
completion SSE stream forwarded verbatim (`data: {"choices":[{"delta":{"content":"..."}}]}`
lines, terminated by `data: [DONE]`). The client accumulates `delta.content`
across chunks to render the streaming reply.

**Side effects**: persists the user's message immediately, and the full
assistant reply once the stream completes, to `ai_conversations` /
`ai_messages` (one conversation per `(user_id, agentType)` — this is how
conversation memory works: the last 20 messages are included as context on
every call).

**Errors**: `400` (missing/invalid `agentType` or empty `message`), `401`
(missing/invalid JWT), `500` (Mistral or database error).

## `POST /meal-analysis`

One-shot structured nutrition estimate from a meal photo.

**Request**

```json
{
  "imageBase64": "<base64 JPEG/PNG, with or without a data: URI prefix>",
  "description": "grilled chicken with rice, optional context",
  "mealEntryId": "optional uuid — if set, writes the result onto meal_entries.ai_analysis"
}
```

**Response**: `200`

```json
{
  "result": {
    "foodName": "Grilled chicken with rice",
    "estimatedCalories": 520,
    "proteinG": 42,
    "carbsG": 55,
    "fatG": 12,
    "confidence": "medium",
    "notes": "Estimate assumes a standard 1-cup rice serving."
  }
}
```

**Errors**: `400` (missing `imageBase64`), `401`, `500`.

## `POST /daily-planner`

One-shot structured daily plan, generated from the caller's profile,
recent workout sessions, and recent meal logs (fetched server-side — the
client sends no body). Also persists the result as an `ai_insights` row.

**Request**: `{}` (empty body)

**Response**: `200`

```json
{
  "plan": {
    "summary": "Upper body focus today given yesterday's leg session...",
    "workoutSuggestion": {
      "focus": "Push (chest/shoulders/triceps)",
      "durationMinutes": 45,
      "exercises": ["Barbell Bench Press", "Overhead Press", "Triceps Rope Pushdown"]
    },
    "nutritionTargets": {
      "calories": 2400,
      "proteinG": 160,
      "carbsG": 240,
      "fatG": 75,
      "waterMl": 3000
    },
    "recoveryTip": "Your last two sessions were high-volume — prioritize 8h sleep tonight."
  }
}
```

**Errors**: `401`, `500`.

## Adding a new agent / function

1. Add the agent's key + system prompt to
   `supabase/functions/_shared/agents.ts` (`AGENT_SYSTEM_PROMPTS`).
2. If it's conversational, no new function is needed — route it through
   `ai-proxy` with the new `agentType`.
3. If it's a one-shot structured action (like `meal-analysis` /
   `daily-planner`), create `supabase/functions/<name>/index.ts` following
   the same pattern: `buildRequestContext(req)` for auth, `completeStructured`
   or `completeVisionStructured` from `_shared/mistral.ts`, then persist
   whatever's relevant with the `adminClient`.
4. Add the new function name to `supabase/config.toml` under
   `[functions.<name>]` and to the client's `AppConstants` (`lib/core/constants/app_constants.dart`).
