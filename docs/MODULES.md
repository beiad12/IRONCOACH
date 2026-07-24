# Modules

One entry per feature module (`lib/features/<name>/`). Each follows the
same `domain/` → `data/` → `presentation/` split described in
[`ARCHITECTURE.md`](ARCHITECTURE.md); this doc focuses on what each module
*does* and where its interesting logic lives.

## `core/`

Not a feature — shared infrastructure every feature depends on:

- `theme/` — Material 3 dark/light themes, brand palette, typography.
- `router/` — `GoRouter` config, route path constants, auth-gated redirect.
- `error/` — `Failure` union + low-level `Exception` types.
- `utils/result.dart` — `Result<T> = Either<Failure, T>` alias.
- `network/supabase_client_provider.dart` — the one place `Supabase.instance.client` is read.
- `local_db/` — Drift database (offline cache + sync outbox).
- `sync/sync_engine.dart` — drains the offline outbox against Supabase.
- `services/notification_service.dart` — local notification scheduling wrapper.
- `widgets/` — shared UI: buttons, text fields, empty/error states, `AsyncValueWidget`.

## `auth`

Email/password, Google, and Apple sign-in (via Supabase Auth OAuth),
password reset, and the post-signup onboarding flow (goal / experience
level / units). `AuthRepository.watchAuthState()` is the single source of
truth the router's redirect logic listens to.

## `profile`

The user's `profiles` row: display name, bio, height/weight, fitness
level, primary goal, public/private visibility. Onboarding writes here.

## `workouts`

The largest module — exercise library, workout templates, the rule-based
`WorkoutGeneratorService` (offline, no AI call required), and the
offline-first active-workout logger (`ActiveWorkoutController` +
`WorkoutSessionRepository`, see the sync sequence diagram in
`ARCHITECTURE.md`). Also owns favorites (exercises and templates) and
workout history. `RestTimerController` runs the between-set countdown.

## `ai_coach`

The AI system's client side. `AgentType` enumerates the six agents;
`AiRepository` streams chat via the `ai-proxy` Edge Function
(`streamMessage`), and calls the two one-shot Edge Functions for
`generateDailyPlan` and `analyzeMealPhoto`. `ChatController` is a
per-agent Riverpod notifier managing the optimistic user-message /
streaming-assistant-message lifecycle. See `docs/API.md` for the wire
contract.

## `nutrition`

Calorie/macro/water tracking. `NutritionRepository` combines the app's own
`food_items` cache with the free Open Food Facts API for barcode lookups
(`OpenFoodFactsDataSource`) — a scanned barcode checks the local cache
first, then falls back to a live lookup and caches the result for next
time. Meal photo logging calls into `ai_coach`'s `analyzeMealPhoto` for an
AI-estimated nutrition breakdown.

## `progress`

Body measurements (weight + 6 tape-measure fields), progress photos
(uploaded to the private `progress-photos` storage bucket), and personal
records (read from the `personal_records` table, which the database
maintains automatically — see `ARCHITECTURE.md`'s server-side automation
section). Weight trend is charted with `fl_chart`.

## `gamification`

XP/levels, workout streaks, achievements, and challenges. Almost entirely
**read-only from the client** — `user_levels` and `user_achievements` are
written only by `security definer` Postgres functions triggered off real
actions (completing a workout), so a compromised client can't grant itself
XP. Challenges are the one exception: joining/progress is client-writable
under RLS scoped to the caller's own participant row.

## `social`

Friends (request/accept/block via `friendships`), workout sharing (a
`Post` referencing a `workout_session_id`, created from the workout
summary screen's "Share" button), likes, comments, and a leaderboard
(`leaderboard_view`, a `security_invoker` view joining profiles + levels +
streaks so it respects each profile's own visibility RLS).

## `notifications`

Local reminder scheduling (`flutter_local_notifications`, wrapped by
`core/services/notification_service.dart`) for workout/nutrition/recovery
reminders, driven by per-user preferences persisted in
`notification_preferences`. Also surfaces `ai_insights` (rows written by
the `daily-planner` Edge Function) as an in-app feed.

## `home`

The dashboard tab: greeting, current streak, today's nutrition ring,
quick-start workout action, and the latest AI insights — a thin
composition layer over providers from `gamification`, `nutrition`,
`notifications`, and `ai_coach`. Deliberately has no `domain`/`data` layers
of its own since it owns no state, only composes other features'.
