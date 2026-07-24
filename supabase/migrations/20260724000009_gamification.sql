create table public.achievements (
  id uuid primary key default extensions.uuid_generate_v4(),
  code text unique not null, -- stable machine key, e.g. "first_workout"
  name text not null,
  description text not null,
  icon text not null,
  xp_reward integer not null default 50,
  tier text not null default 'bronze' check (tier in ('bronze', 'silver', 'gold', 'platinum')),
  criteria jsonb not null -- e.g. {"type": "workout_count", "threshold": 1}
);

alter table public.achievements enable row level security;

create policy "Achievements are readable by any authenticated user"
  on public.achievements for select
  to authenticated
  using (true);

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

alter table public.user_achievements enable row level security;

create policy "Users view their own unlocked achievements"
  on public.user_achievements for select
  using (auth.uid() = user_id);

create policy "Only the backend unlocks achievements"
  on public.user_achievements for insert
  to service_role
  with check (true);

create table public.user_levels (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  level integer not null default 1,
  total_xp integer not null default 0,
  xp_to_next_level integer not null default 100,
  updated_at timestamptz not null default now()
);

create trigger set_user_levels_updated_at
  before update on public.user_levels
  for each row execute function public.set_updated_at();

alter table public.user_levels enable row level security;

create policy "Levels are readable by any authenticated user"
  on public.user_levels for select
  to authenticated
  using (true);

create policy "Only the backend updates levels"
  on public.user_levels for update
  to service_role
  using (true) with check (true);

create policy "Only the backend inserts levels"
  on public.user_levels for insert
  to service_role
  with check (true);

create table public.streaks (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  streak_type text not null default 'workout' check (streak_type in ('workout', 'nutrition_log')),
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_activity_date date,
  updated_at timestamptz not null default now()
);

create trigger set_streaks_updated_at
  before update on public.streaks
  for each row execute function public.set_updated_at();

alter table public.streaks enable row level security;

create policy "Users manage their own streak row"
  on public.streaks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table public.challenges (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  description text not null,
  challenge_type text not null check (challenge_type in ('workout_count', 'volume', 'streak', 'nutrition_adherence')),
  target_value numeric(10, 2) not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  xp_reward integer not null default 100,
  created_by uuid references public.profiles (id) on delete set null,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.challenges enable row level security;

create policy "Public challenges are readable by any authenticated user"
  on public.challenges for select
  to authenticated
  using (is_public or created_by = auth.uid());

create policy "Users create their own challenges"
  on public.challenges for insert
  with check (created_by = auth.uid());

create table public.challenge_participants (
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  progress_value numeric(10, 2) not null default 0,
  joined_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (challenge_id, user_id)
);

alter table public.challenge_participants enable row level security;

create policy "Participants are visible to any authenticated user (leaderboard)"
  on public.challenge_participants for select
  to authenticated
  using (true);

create policy "Users join challenges as themselves"
  on public.challenge_participants for insert
  with check (user_id = auth.uid());

create policy "Users update their own challenge progress"
  on public.challenge_participants for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
