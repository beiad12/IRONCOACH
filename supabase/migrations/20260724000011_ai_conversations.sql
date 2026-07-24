-- One conversation thread per (user, agent). Keeping agent_type on the
-- conversation (not just the message) lets each specialized coach keep
-- independent memory/context.
create table public.ai_conversations (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  agent_type text not null check (
    agent_type in (
      'workout_coach', 'nutrition_coach', 'recovery_coach',
      'motivation_coach', 'meal_analysis', 'daily_planner'
    )
  ),
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, agent_type)
);

create trigger set_ai_conversations_updated_at
  before update on public.ai_conversations
  for each row execute function public.set_updated_at();

alter table public.ai_conversations enable row level security;

create policy "Users manage their own AI conversations"
  on public.ai_conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table public.ai_messages (
  id uuid primary key default extensions.uuid_generate_v4(),
  conversation_id uuid not null references public.ai_conversations (id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  structured_output jsonb, -- e.g. generated workout template, macro plan
  token_count integer,
  created_at timestamptz not null default now()
);

create index ai_messages_conversation_idx on public.ai_messages (conversation_id, created_at);

alter table public.ai_messages enable row level security;

create policy "Users manage messages in their own conversations"
  on public.ai_messages for all
  using (exists (select 1 from public.ai_conversations c where c.id = conversation_id and c.user_id = auth.uid()))
  with check (exists (select 1 from public.ai_conversations c where c.id = conversation_id and c.user_id = auth.uid()));

-- The ai-proxy edge function calls this with the service role after it has
-- already verified the caller's JWT, so message inserts always happen
-- server-side even though the policy above would also allow the client
-- to write directly (used for optimistic local echo of the user's turn).
