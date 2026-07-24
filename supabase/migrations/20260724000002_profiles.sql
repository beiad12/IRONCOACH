-- profiles: one row per auth.users row, created automatically on signup.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text,
  date_of_birth date,
  sex text check (sex in ('male', 'female', 'other', 'prefer_not_to_say')),
  height_cm numeric(5, 2),
  weight_kg numeric(5, 2),
  fitness_level text check (fitness_level in ('beginner', 'intermediate', 'advanced')) default 'beginner',
  primary_goal text check (
    primary_goal in ('lose_fat', 'build_muscle', 'maintain', 'improve_endurance', 'general_health')
  ),
  units text check (units in ('metric', 'imperial')) not null default 'metric',
  timezone text not null default 'UTC',
  is_public boolean not null default true,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Public-facing user profile, 1:1 with auth.users.';

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone if public, or by the owner"
  on public.profiles for select
  using (is_public or auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Users can delete their own profile"
  on public.profiles for delete
  using (auth.uid() = id);

-- Auto-provision a profile row (with a unique-ish default username) whenever
-- a new auth.users row is created, covering email, Google, and Apple signups.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
