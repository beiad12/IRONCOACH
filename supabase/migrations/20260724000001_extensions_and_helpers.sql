-- Extensions
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "pg_trgm" with schema extensions;

-- Generic updated_at trigger used by nearly every table below.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Helper used inside RLS policies for friend-scoped visibility. Declared
-- here (before `friendships` exists) as a forward-referenced function;
-- the body is created in the social migration and this stub is replaced
-- via `create or replace` there.
create or replace function public.are_friends(user_a uuid, user_b uuid)
returns boolean
language sql
stable
as $$
  select false;
$$;
