-- A logged workout session (an actual performed workout, as opposed to a
-- template). `id` is client-generated (uuid) so the Flutter app can create
-- it offline and reconcile via upsert once connectivity returns.
create table public.workout_sessions (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  template_id uuid references public.workout_templates (id) on delete set null,
  name text not null default 'Workout',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  notes text,
  total_volume_kg numeric(10, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index workout_sessions_user_started_idx on public.workout_sessions (user_id, started_at desc);

create trigger set_workout_sessions_updated_at
  before update on public.workout_sessions
  for each row execute function public.set_updated_at();

alter table public.workout_sessions enable row level security;

create policy "Users manage their own workout sessions"
  on public.workout_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Individual set logs (weight/reps/RPE) belonging to a session.
create table public.workout_sets (
  id uuid primary key default extensions.uuid_generate_v4(),
  session_id uuid not null references public.workout_sessions (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  set_number integer not null,
  weight_kg numeric(6, 2),
  reps integer,
  rpe numeric(3, 1) check (rpe between 1 and 10),
  rest_seconds integer,
  is_warmup boolean not null default false,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index workout_sets_session_idx on public.workout_sets (session_id, set_number);
create index workout_sets_exercise_idx on public.workout_sets (exercise_id);

alter table public.workout_sets enable row level security;

create policy "Users manage sets on their own sessions"
  on public.workout_sets for all
  using (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = auth.uid()))
  with check (exists (select 1 from public.workout_sessions s where s.id = session_id and s.user_id = auth.uid()));

-- Keeps workout_sessions.total_volume_kg denormalized for fast history/
-- dashboard queries (volume = sum(weight * reps) across working sets).
create or replace function public.recalc_session_volume()
returns trigger
language plpgsql
as $$
declare
  affected_session uuid := coalesce(new.session_id, old.session_id);
begin
  update public.workout_sessions
  set total_volume_kg = (
    select coalesce(sum(weight_kg * reps), 0)
    from public.workout_sets
    where session_id = affected_session and is_warmup = false and is_completed = true
  )
  where id = affected_session;
  return null;
end;
$$;

create trigger workout_sets_recalc_volume
  after insert or update or delete on public.workout_sets
  for each row execute function public.recalc_session_volume();
