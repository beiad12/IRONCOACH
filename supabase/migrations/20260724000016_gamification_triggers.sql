-- Server-side gamification engine: XP/levels, streaks, and achievement
-- unlocks are only ever written by these SECURITY DEFINER functions
-- (never directly by the client — see the `user_levels`/`user_achievements`
-- RLS policies), triggered off real user actions like completing a workout.

create or replace function public.award_xp(p_user_id uuid, p_amount integer)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  current_row public.user_levels%rowtype;
  new_total integer;
  new_level integer;
begin
  insert into public.user_levels (user_id, level, total_xp, xp_to_next_level)
  values (p_user_id, 1, 0, 100)
  on conflict (user_id) do nothing;

  select * into current_row from public.user_levels where user_id = p_user_id;

  new_total := current_row.total_xp + p_amount;
  new_level := current_row.level;

  -- Simple curve: each level requires level * 100 XP more than the last.
  while new_total >= (new_level * 100) loop
    new_total := new_total - (new_level * 100);
    new_level := new_level + 1;
  end loop;

  update public.user_levels
  set total_xp = current_row.total_xp + p_amount,
      level = new_level,
      xp_to_next_level = (new_level * 100) - new_total
  where user_id = p_user_id;
end;
$$;

create or replace function public.bump_streak(p_user_id uuid, p_streak_type text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  today date := current_date;
  streak_row public.streaks%rowtype;
begin
  insert into public.streaks (user_id, streak_type, current_streak, longest_streak, last_activity_date)
  values (p_user_id, p_streak_type, 0, 0, null)
  on conflict (user_id) do nothing;

  select * into streak_row from public.streaks where user_id = p_user_id;

  if streak_row.last_activity_date = today then
    return; -- already counted today
  elsif streak_row.last_activity_date = today - interval '1 day' then
    update public.streaks
    set current_streak = streak_row.current_streak + 1,
        longest_streak = greatest(streak_row.longest_streak, streak_row.current_streak + 1),
        last_activity_date = today
    where user_id = p_user_id;
  else
    update public.streaks
    set current_streak = 1,
        longest_streak = greatest(streak_row.longest_streak, 1),
        last_activity_date = today
    where user_id = p_user_id;
  end if;
end;
$$;

create or replace function public.check_and_unlock_achievements(p_user_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  workout_count integer;
  streak_count integer;
  pr_count integer;
  achievement record;
begin
  select count(*) into workout_count from public.workout_sessions
    where user_id = p_user_id and completed_at is not null;
  select coalesce(current_streak, 0) into streak_count from public.streaks
    where user_id = p_user_id and streak_type = 'workout';
  select count(*) into pr_count from public.personal_records where user_id = p_user_id;

  for achievement in select * from public.achievements loop
    if exists (
      select 1 from public.user_achievements
      where user_id = p_user_id and achievement_id = achievement.id
    ) then
      continue;
    end if;

    if (achievement.criteria ->> 'type' = 'workout_count'
        and workout_count >= (achievement.criteria ->> 'threshold')::integer)
      or (achievement.criteria ->> 'type' = 'streak'
        and streak_count >= (achievement.criteria ->> 'threshold')::integer)
      or (achievement.criteria ->> 'type' = 'pr_count'
        and pr_count >= (achievement.criteria ->> 'threshold')::integer)
    then
      insert into public.user_achievements (user_id, achievement_id)
      values (p_user_id, achievement.id)
      on conflict do nothing;
      perform public.award_xp(p_user_id, achievement.xp_reward);
    end if;
  end loop;
end;
$$;

create or replace function public.handle_workout_completed()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.completed_at is not null and old.completed_at is null then
    perform public.award_xp(new.user_id, 20);
    perform public.bump_streak(new.user_id, 'workout');
    perform public.check_and_unlock_achievements(new.user_id);
  end if;
  return new;
end;
$$;

create trigger workout_sessions_award_progress
  after update on public.workout_sessions
  for each row execute function public.handle_workout_completed();

-- Also unlock the "first_workout" style achievements the moment a session
-- is first created (some achievements key off starting, not finishing).
create or replace function public.handle_workout_started()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  perform public.check_and_unlock_achievements(new.user_id);
  return new;
end;
$$;

create trigger workout_sessions_check_on_insert
  after insert on public.workout_sessions
  for each row execute function public.handle_workout_started();
