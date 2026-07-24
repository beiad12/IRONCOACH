create table public.favorite_exercises (
  user_id uuid not null references public.profiles (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, exercise_id)
);

alter table public.favorite_exercises enable row level security;

create policy "Users manage their own favorite exercises"
  on public.favorite_exercises for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table public.favorite_templates (
  user_id uuid not null references public.profiles (id) on delete cascade,
  template_id uuid not null references public.workout_templates (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, template_id)
);

alter table public.favorite_templates enable row level security;

create policy "Users manage their own favorite templates"
  on public.favorite_templates for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
