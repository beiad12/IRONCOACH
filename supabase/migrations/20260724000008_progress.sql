create table public.body_measurements (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  measured_at timestamptz not null default now(),
  weight_kg numeric(5, 2),
  body_fat_pct numeric(4, 1),
  chest_cm numeric(5, 2),
  waist_cm numeric(5, 2),
  hips_cm numeric(5, 2),
  bicep_cm numeric(5, 2),
  thigh_cm numeric(5, 2),
  neck_cm numeric(5, 2),
  notes text,
  created_at timestamptz not null default now()
);

create index body_measurements_user_measured_idx on public.body_measurements (user_id, measured_at desc);

alter table public.body_measurements enable row level security;

create policy "Users manage their own body measurements"
  on public.body_measurements for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table public.progress_photos (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  taken_at timestamptz not null default now(),
  angle text check (angle in ('front', 'side', 'back')),
  photo_url text not null,
  weight_kg numeric(5, 2),
  created_at timestamptz not null default now()
);

create index progress_photos_user_taken_idx on public.progress_photos (user_id, taken_at desc);

alter table public.progress_photos enable row level security;

create policy "Users manage their own progress photos"
  on public.progress_photos for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- One row per (user, exercise, rep_range) best-effort record, upserted
-- whenever a logged set beats the existing record (see recalc trigger).
create table public.personal_records (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  record_type text not null check (record_type in ('1rm_estimate', 'max_weight', 'max_reps', 'max_volume')),
  value numeric(10, 2) not null,
  achieved_at timestamptz not null default now(),
  workout_set_id uuid references public.workout_sets (id) on delete set null,
  unique (user_id, exercise_id, record_type)
);

create index personal_records_user_idx on public.personal_records (user_id);

alter table public.personal_records enable row level security;

create policy "Users manage their own personal records"
  on public.personal_records for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Epley estimated 1RM = weight * (1 + reps / 30). Runs after every
-- completed, non-warmup set and upserts a PR row when it's a new best.
create or replace function public.recalc_personal_records()
returns trigger
language plpgsql
as $$
declare
  session_user_id uuid;
  estimated_1rm numeric(10, 2);
begin
  if new.is_completed = false or new.is_warmup = true or new.weight_kg is null or new.reps is null then
    return new;
  end if;

  select user_id into session_user_id from public.workout_sessions where id = new.session_id;
  estimated_1rm := round((new.weight_kg * (1 + new.reps::numeric / 30))::numeric, 2);

  insert into public.personal_records (user_id, exercise_id, record_type, value, achieved_at, workout_set_id)
  values (session_user_id, new.exercise_id, '1rm_estimate', estimated_1rm, now(), new.id)
  on conflict (user_id, exercise_id, record_type)
  do update set value = excluded.value, achieved_at = excluded.achieved_at, workout_set_id = excluded.workout_set_id
  where excluded.value > public.personal_records.value;

  insert into public.personal_records (user_id, exercise_id, record_type, value, achieved_at, workout_set_id)
  values (session_user_id, new.exercise_id, 'max_weight', new.weight_kg, now(), new.id)
  on conflict (user_id, exercise_id, record_type)
  do update set value = excluded.value, achieved_at = excluded.achieved_at, workout_set_id = excluded.workout_set_id
  where excluded.value > public.personal_records.value;

  return new;
end;
$$;

create trigger workout_sets_recalc_prs
  after insert or update on public.workout_sets
  for each row execute function public.recalc_personal_records();
