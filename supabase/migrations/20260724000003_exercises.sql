-- Global exercise library. Publicly readable; writable only by admins
-- (service role / an `is_admin` claim), so user-generated custom exercises
-- live in `user_exercises` instead and keep the canonical library curated.
create table public.exercises (
  id uuid primary key default extensions.uuid_generate_v4(),
  name text not null,
  category text not null check (
    category in ('strength', 'cardio', 'mobility', 'plyometric', 'balance')
  ),
  primary_muscle text not null,
  secondary_muscles text[] not null default '{}',
  equipment text,
  difficulty text not null check (difficulty in ('beginner', 'intermediate', 'advanced')),
  mechanic text check (mechanic in ('compound', 'isolation')),
  instructions text,
  video_url text,
  image_url text,
  is_unilateral boolean not null default false,
  search_vector tsvector generated always as (
    to_tsvector('english', name || ' ' || primary_muscle || ' ' || coalesce(equipment, ''))
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index exercises_search_idx on public.exercises using gin (search_vector);
create index exercises_category_idx on public.exercises (category);
create index exercises_primary_muscle_idx on public.exercises (primary_muscle);

create trigger set_exercises_updated_at
  before update on public.exercises
  for each row execute function public.set_updated_at();

alter table public.exercises enable row level security;

create policy "Exercises are readable by any authenticated user"
  on public.exercises for select
  to authenticated
  using (true);

create policy "Only service role can modify the exercise library"
  on public.exercises for all
  to service_role
  using (true)
  with check (true);

-- User-created custom exercises, private to their creator by default.
create table public.user_exercises (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  category text not null,
  primary_muscle text not null,
  secondary_muscles text[] not null default '{}',
  equipment text,
  instructions text,
  created_at timestamptz not null default now()
);

alter table public.user_exercises enable row level security;

create policy "Users manage their own custom exercises"
  on public.user_exercises for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
