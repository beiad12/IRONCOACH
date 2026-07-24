create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  workout_reminders_enabled boolean not null default true,
  workout_reminder_time time not null default '18:00',
  nutrition_reminders_enabled boolean not null default true,
  nutrition_reminder_time time not null default '12:00',
  recovery_reminders_enabled boolean not null default true,
  ai_insights_enabled boolean not null default true,
  push_token text,
  updated_at timestamptz not null default now()
);

create trigger set_notification_preferences_updated_at
  before update on public.notification_preferences
  for each row execute function public.set_updated_at();

alter table public.notification_preferences enable row level security;

create policy "Users manage their own notification preferences"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- AI-generated insights queued for delivery (surfaced as a push/local
-- notification, then marked read once opened in-app).
create table public.ai_insights (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  agent_type text not null,
  title text not null,
  body text not null,
  data jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index ai_insights_user_created_idx on public.ai_insights (user_id, created_at desc);

alter table public.ai_insights enable row level security;

create policy "Users manage their own AI insights"
  on public.ai_insights for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
