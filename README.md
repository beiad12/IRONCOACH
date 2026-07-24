# IronCoach

IronCoach is an offline-first, AI-powered fitness platform built with
Flutter and Supabase: workout programming and logging, nutrition tracking,
progress analytics, gamification, social features, and six specialized AI
coaches backed by Mistral.

See [`docs/`](docs/) for full documentation:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Clean Architecture layers, DI, offline sync, diagrams
- [`docs/MODULES.md`](docs/MODULES.md) — what every feature module does
- [`docs/DATABASE.md`](docs/DATABASE.md) — schema, RLS, ERD
- [`docs/API.md`](docs/API.md) — Edge Function contracts (AI proxy, meal analysis, daily planner)

## Stack

- **Client**: Flutter 3.24+, Riverpod (+ `riverpod_generator`), GoRouter, Freezed, `json_serializable`, Flutter Hooks, Drift (offline cache), Material 3.
- **Backend**: Supabase — Postgres + Row Level Security, Realtime, Storage, Edge Functions (Deno).
- **AI**: Mistral API, called only from Edge Functions — the API key never reaches the client.

## Getting started

### 1. Backend

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push                       # applies supabase/migrations/*.sql
supabase secrets set MISTRAL_API_KEY=sk-...
supabase functions deploy ai-proxy
supabase functions deploy meal-analysis
supabase functions deploy daily-planner
```

For local development instead: `supabase start` spins up Postgres, Auth,
Storage, and Realtime in Docker; `supabase functions serve` runs the Edge
Functions locally.

### 2. Client

```bash
cp .env.example .env      # fill in SUPABASE_URL / SUPABASE_ANON_KEY
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed/json_serializable/riverpod/drift codegen
flutter run
```

### 3. Tests

```bash
flutter test                          # unit + widget
flutter test integration_test         # end-to-end (needs a Supabase project — see integration_test/app_test.dart)
```

## Project layout

```
lib/
  core/                 # theme, router, DI, error handling, offline sync engine, shared widgets
  features/
    auth/                nutrition/           progress/
    profile/              ai_coach/            gamification/
    workouts/             social/              notifications/
    home/
    <feature>/
      domain/            # entities, repository interfaces, use cases — no Flutter/Supabase imports
      data/               # repository implementations, remote/local data sources
      presentation/       # Riverpod providers, screens, widgets
supabase/
  migrations/            # SQL schema + RLS, in apply order
  functions/             # ai-proxy, meal-analysis, daily-planner (Deno)
test/                    # unit + widget tests
integration_test/        # end-to-end tests
```

Every feature follows the same three-layer Clean Architecture split, so
once you've read one (`auth` is the smallest full example), the rest follow
the same shape.

## Security notes

- The Mistral API key lives only in Supabase Edge Function secrets
  (`supabase/functions/_shared/mistral.ts`) — it is never bundled into the
  client and never logged.
- Every table has Row Level Security enabled; policies are defined
  alongside each table in `supabase/migrations/`.
- Storage buckets enforce `<bucket>/<user_id>/...` path ownership via
  storage object policies.
