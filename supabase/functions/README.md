# IronCoach Edge Functions

Three Deno Edge Functions, deployed to Supabase, proxy every AI call so the
Mistral API key never reaches the client:

| Function | Purpose | Client caller |
|---|---|---|
| `ai-proxy` | Streaming chat with a specialized coach agent, with per-agent conversation memory | `AiRepository.streamMessage` |
| `meal-analysis` | Structured nutrition estimate from a meal photo | `NutritionRepository.analyzeMealPhoto` |
| `daily-planner` | Structured daily workout/nutrition/recovery plan, stored as an insight | `AiRepository.generateDailyPlan` |

## Local development

```bash
supabase start
supabase secrets set MISTRAL_API_KEY=sk-... --env-file supabase/.env
supabase functions serve --env-file supabase/.env
```

## Deploying

```bash
supabase functions deploy ai-proxy
supabase functions deploy meal-analysis
supabase functions deploy daily-planner
supabase secrets set MISTRAL_API_KEY=sk-...
```

## Security notes

- `MISTRAL_API_KEY` is read only in `_shared/mistral.ts` via `Deno.env` —
  it is a Supabase secret, never an app build-time constant, never logged.
- Every function verifies the caller's Supabase JWT (`_shared/supabase_ctx.ts`)
  before doing any work; there is no unauthenticated path.
- Writes that must bypass RLS (persisting assistant messages, insights) use
  the service-role client, scoped explicitly to the verified `userId` — the
  service role is never used to satisfy arbitrary client-supplied filters.
