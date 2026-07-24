-- Seed a starter exercise library and achievement set so a fresh
-- environment is immediately usable end-to-end (generator, logger,
-- achievements screen) without manual data entry.
insert into public.exercises
  (name, category, primary_muscle, secondary_muscles, equipment, difficulty, mechanic, instructions)
values
  ('Barbell Back Squat', 'strength', 'quadriceps', array['glutes', 'hamstrings', 'core'], 'barbell', 'intermediate', 'compound', 'Bar on upper traps, feet shoulder-width, squat to depth keeping chest up.'),
  ('Barbell Bench Press', 'strength', 'chest', array['triceps', 'shoulders'], 'barbell', 'intermediate', 'compound', 'Lower bar to mid-chest with control, press to lockout.'),
  ('Conventional Deadlift', 'strength', 'hamstrings', array['glutes', 'back', 'core'], 'barbell', 'advanced', 'compound', 'Hinge at hips, neutral spine, drive through the floor to stand.'),
  ('Pull-Up', 'strength', 'back', array['biceps'], 'pull-up bar', 'intermediate', 'compound', 'Dead hang to chin over the bar, control the descent.'),
  ('Overhead Press', 'strength', 'shoulders', array['triceps', 'core'], 'barbell', 'intermediate', 'compound', 'Press bar from shoulders to lockout overhead, brace the core.'),
  ('Barbell Row', 'strength', 'back', array['biceps', 'rear delts'], 'barbell', 'intermediate', 'compound', 'Hinge forward, row bar to lower ribs, squeeze shoulder blades.'),
  ('Dumbbell Lunge', 'strength', 'quadriceps', array['glutes', 'hamstrings'], 'dumbbell', 'beginner', 'compound', 'Step forward, lower back knee toward the floor, push back up.'),
  ('Dumbbell Bicep Curl', 'strength', 'biceps', array[]::text[], 'dumbbell', 'beginner', 'isolation', 'Curl dumbbells to shoulders keeping elbows pinned.'),
  ('Triceps Rope Pushdown', 'strength', 'triceps', array[]::text[], 'cable', 'beginner', 'isolation', 'Push rope down and out, extend elbows fully.'),
  ('Plank', 'strength', 'core', array[]::text[], 'bodyweight', 'beginner', 'isolation', 'Hold a straight line from shoulders to ankles, brace the abs.'),
  ('Kettlebell Swing', 'plyometric', 'glutes', array['hamstrings', 'core'], 'kettlebell', 'intermediate', 'compound', 'Hinge and snap the hips to drive the bell to shoulder height.'),
  ('Treadmill Run', 'cardio', 'cardiovascular', array[]::text[], 'treadmill', 'beginner', null, 'Maintain steady pace/incline per program.'),
  ('Bodyweight Push-Up', 'strength', 'chest', array['triceps', 'shoulders'], 'bodyweight', 'beginner', 'compound', 'Lower chest to just above the floor, press back up keeping a straight line.'),
  ('Dumbbell Shoulder Press', 'strength', 'shoulders', array['triceps'], 'dumbbell', 'beginner', 'compound', 'Press dumbbells overhead from shoulder height to lockout.'),
  ('Leg Press', 'strength', 'quadriceps', array['glutes', 'hamstrings'], 'machine', 'beginner', 'compound', 'Lower sled with control to 90°, press through the heels.')
on conflict do nothing;

insert into public.achievements (code, name, description, icon, xp_reward, tier, criteria)
values
  ('first_workout', 'First Rep', 'Log your very first workout', 'flag', 25, 'bronze', '{"type": "workout_count", "threshold": 1}'),
  ('ten_workouts', 'Consistency Builder', 'Complete 10 workouts', 'trending_up', 100, 'silver', '{"type": "workout_count", "threshold": 10}'),
  ('hundred_workouts', 'Iron Veteran', 'Complete 100 workouts', 'military_tech', 500, 'gold', '{"type": "workout_count", "threshold": 100}'),
  ('seven_day_streak', 'Week Warrior', 'Reach a 7-day workout streak', 'local_fire_department', 75, 'bronze', '{"type": "streak", "threshold": 7}'),
  ('thirty_day_streak', 'Unstoppable', 'Reach a 30-day workout streak', 'whatshot', 300, 'gold', '{"type": "streak", "threshold": 30}'),
  ('first_pr', 'New Best', 'Set your first personal record', 'emoji_events', 25, 'bronze', '{"type": "pr_count", "threshold": 1}'),
  ('nutrition_week', 'Dialed In', 'Log nutrition for 7 consecutive days', 'restaurant', 75, 'bronze', '{"type": "nutrition_streak", "threshold": 7}'),
  ('social_butterfly', 'Social Butterfly', 'Add 5 friends', 'group', 50, 'bronze', '{"type": "friend_count", "threshold": 5}')
on conflict (code) do nothing;
