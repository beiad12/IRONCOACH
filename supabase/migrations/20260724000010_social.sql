create table public.friendships (
  id uuid primary key default extensions.uuid_generate_v4(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friendships_no_self check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (requester_id, addressee_id)
);

create index friendships_addressee_idx on public.friendships (addressee_id, status);
create index friendships_requester_idx on public.friendships (requester_id, status);

alter table public.friendships enable row level security;

create policy "Users see friendships they are part of"
  on public.friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users send friend requests as themselves"
  on public.friendships for insert
  with check (auth.uid() = requester_id);

create policy "Either party can update a friendship (accept/block)"
  on public.friendships for update
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Either party can delete/unfriend"
  on public.friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- Now that `friendships` exists, replace the forward-declared stub from
-- the extensions migration with the real bidirectional lookup.
create or replace function public.are_friends(user_a uuid, user_b uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.friendships
    where status = 'accepted'
      and (
        (requester_id = user_a and addressee_id = user_b) or
        (requester_id = user_b and addressee_id = user_a)
      )
  );
$$;

-- Shared workouts / progress updates on the social feed.
create table public.posts (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_type text not null check (post_type in ('workout', 'progress_photo', 'achievement', 'text')),
  workout_session_id uuid references public.workout_sessions (id) on delete set null,
  achievement_id uuid references public.achievements (id) on delete set null,
  caption text,
  media_url text,
  created_at timestamptz not null default now()
);

create index posts_user_created_idx on public.posts (user_id, created_at desc);

alter table public.posts enable row level security;

create policy "Posts are visible to the author, friends, or if profile is public"
  on public.posts for select
  using (
    auth.uid() = user_id
    or public.are_friends(auth.uid(), user_id)
    or exists (select 1 from public.profiles p where p.id = user_id and p.is_public)
  );

create policy "Users create their own posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Users manage their own posts"
  on public.posts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users delete their own posts"
  on public.posts for delete using (auth.uid() = user_id);

create table public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.post_likes enable row level security;

create policy "Likes are visible to anyone who can see the post"
  on public.post_likes for select
  using (exists (select 1 from public.posts p where p.id = post_id));

create policy "Users like posts as themselves"
  on public.post_likes for insert
  with check (auth.uid() = user_id);

create policy "Users remove their own likes"
  on public.post_likes for delete
  using (auth.uid() = user_id);

create table public.post_comments (
  id uuid primary key default extensions.uuid_generate_v4(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index post_comments_post_idx on public.post_comments (post_id, created_at);

alter table public.post_comments enable row level security;

create policy "Comments are visible to anyone who can see the post"
  on public.post_comments for select
  using (exists (select 1 from public.posts p where p.id = post_id));

create policy "Users comment as themselves"
  on public.post_comments for insert
  with check (auth.uid() = user_id);

create policy "Users delete their own comments"
  on public.post_comments for delete
  using (auth.uid() = user_id);

-- Leaderboard view: total XP + current streak, joined with the profile,
-- filtered at query time by the caller to "my friends" or "global".
create view public.leaderboard_view
with (security_invoker = true)
as
select
  p.id as user_id,
  p.username,
  p.display_name,
  p.avatar_url,
  coalesce(ul.level, 1) as level,
  coalesce(ul.total_xp, 0) as total_xp,
  coalesce(s.current_streak, 0) as current_streak
from public.profiles p
left join public.user_levels ul on ul.user_id = p.id
left join public.streaks s on s.user_id = p.id and s.streak_type = 'workout';
