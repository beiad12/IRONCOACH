-- Storage buckets for user-generated media. All private by default;
-- access is enforced by per-object RLS policies keyed off the folder
-- structure `<bucket>/<user_id>/<filename>`, which every client upload
-- must follow.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('meal-photos', 'meal-photos', false, 10485760, array['image/png', 'image/jpeg', 'image/webp']),
  ('progress-photos', 'progress-photos', false, 10485760, array['image/png', 'image/jpeg', 'image/webp']),
  ('post-media', 'post-media', false, 15728640, array['image/png', 'image/jpeg', 'image/webp', 'video/mp4'])
on conflict (id) do nothing;

-- avatars: public read (profile pictures shown to anyone), owner-only write.
create policy "Avatar images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users upload their own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users update their own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users delete their own avatar"
  on storage.objects for delete
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- meal-photos / progress-photos: strictly private to the owner.
create policy "Users manage their own meal photos"
  on storage.objects for all
  using (bucket_id = 'meal-photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'meal-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users manage their own progress photos"
  on storage.objects for all
  using (bucket_id = 'progress-photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'progress-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- post-media: owner-write, friend/public-read (mirrors the `posts` RLS via
-- the same `are_friends` helper — the object's folder segment is the
-- author's user id, and the corresponding post row governs visibility).
create policy "Users upload their own post media"
  on storage.objects for insert
  with check (bucket_id = 'post-media' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users delete their own post media"
  on storage.objects for delete
  using (bucket_id = 'post-media' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Post media is readable by the owner, friends, or if public"
  on storage.objects for select
  using (
    bucket_id = 'post-media'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.are_friends(auth.uid(), ((storage.foldername(name))[1])::uuid)
      or exists (
        select 1 from public.profiles p
        where p.id = ((storage.foldername(name))[1])::uuid and p.is_public
      )
    )
  );
