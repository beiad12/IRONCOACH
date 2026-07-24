-- Workout templates: reusable/generated workout plans. `owner_id` is null
-- for system-generated templates seeded for all users.
create table public.workout_templates (
  id uuid primary key default extensions.uuid_generate_v4(),
  owner_id uuid references public.profiles (id) on delete cascade,
  name text not null,
  description text,
  goal text check (
    goal in ('strength', 'hypertrophy', 'endurance', 'fat_loss', 'general_fitness')
  ),
  difficulty text check (difficulty in ('beginner', 'intermediate', 'advanced')),
  estimated_duration_minutes integer,
  is_ai_generated boolean not null default false,
  is_public boolean not null default false,
  source_prompt text, -- the AI prompt/params used to generate this, if any
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_workout_templates_updated_at
  before update on public.workout_templates
  for each row execute function public.set_updated_at();

alter table public.workout_templates enable row level security;

create policy "Templates are visible if public, system-owned, or own"
  on public.workout_templates for select
  using (is_public or owner_id is null or owner_id = auth.uid());

create policy "Users create their own templates"
  on public.workout_templates for insert
  with check (owner_id = auth.uid());

create policy "Users modify their own templates"
  on public.workout_templates for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Users delete their own templates"
  on public.workout_templates for delete
  using (owner_id = auth.uid());

-- Ordered exercises within a template, with prescribed sets/reps/rest.
create table public.workout_template_exercises (
  id uuid primary key default extensions.uuid_generate_v4(),
  template_id uuid not null references public.workout_templates (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  position integer not null,
  target_sets integer not null default 3,
  target_reps_min integer,
  target_reps_max integer,
  target_rest_seconds integer default 90,
  target_weight_kg numeric(6, 2),
  notes text
);

create index workout_template_exercises_template_idx on public.workout_template_exercises (template_id, position);

alter table public.workout_template_exercises enable row level security;

create policy "Template exercises inherit their template's visibility"
  on public.workout_template_exercises for select
  using (
    exists (
      select 1 from public.workout_templates t
      where t.id = template_id
        and (t.is_public or t.owner_id is null or t.owner_id = auth.uid())
    )
  );

create policy "Users manage exercises on their own templates"
  on public.workout_template_exercises for all
  using (
    exists (select 1 from public.workout_templates t where t.id = template_id and t.owner_id = auth.uid())
  )
  with check (
    exists (select 1 from public.workout_templates t where t.id = template_id and t.owner_id = auth.uid())
  );
