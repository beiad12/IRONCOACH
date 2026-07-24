-- Enable Realtime (logical replication) on tables the client subscribes to:
-- live workout set updates (multi-device), social feed likes/comments, and
-- streaming-adjacent AI message inserts (used for optimistic UI sync across
-- devices, independent of the edge function's own SSE stream).
alter publication supabase_realtime add table public.workout_sets;
alter publication supabase_realtime add table public.workout_sessions;
alter publication supabase_realtime add table public.post_likes;
alter publication supabase_realtime add table public.post_comments;
alter publication supabase_realtime add table public.ai_messages;
alter publication supabase_realtime add table public.ai_insights;
alter publication supabase_realtime add table public.challenge_participants;

alter table public.workout_sets replica identity full;
alter table public.workout_sessions replica identity full;
