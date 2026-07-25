import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/local_db/database_provider.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/exercise_local_data_source.dart';
import '../../data/datasources/exercise_remote_data_source.dart';
import '../../data/datasources/workout_session_local_data_source.dart';
import '../../data/datasources/workout_session_remote_data_source.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../data/repositories/workout_session_repository_impl.dart';
import '../../data/repositories/workout_template_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/workout_session_repository.dart';
import '../../domain/repositories/workout_template_repository.dart';
import '../../domain/services/workout_generator_service.dart';

part 'workout_providers.g.dart';

@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepositoryImpl(
    remote: ExerciseRemoteDataSource(ref.watch(supabaseClientProvider)),
    local: ExerciseLocalDataSource(ref.watch(appDatabaseProvider)),
    db: ref.watch(appDatabaseProvider),
    currentUserId: () => ref.read(currentUserProvider)?.id,
  );
}

@Riverpod(keepAlive: true)
WorkoutSessionRepository workoutSessionRepository(Ref ref) {
  return WorkoutSessionRepositoryImpl(
    local: WorkoutSessionLocalDataSource(ref.watch(appDatabaseProvider)),
    remote: WorkoutSessionRemoteDataSource(ref.watch(supabaseClientProvider)),
    db: ref.watch(appDatabaseProvider),
    currentUserId: () => ref.read(currentUserProvider)?.id,
    uuid: const Uuid(),
  );
}

@Riverpod(keepAlive: true)
WorkoutTemplateRepository workoutTemplateRepository(Ref ref) {
  return WorkoutTemplateRepositoryImpl(
    ref.watch(supabaseClientProvider),
    () => ref.read(currentUserProvider)?.id,
  );
}

@riverpod
WorkoutGeneratorService workoutGeneratorService(Ref ref) => const WorkoutGeneratorService();

@riverpod
Future<List<Exercise>> exerciseList(Ref ref, ExerciseFilter filter) async {
  final result = await ref.watch(exerciseRepositoryProvider).getExercises(filter);
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<Exercise> exerciseById(Ref ref, String id) async {
  final result = await ref.watch(exerciseRepositoryProvider).getExerciseById(id);
  return result.match((failure) => throw failure, (exercise) => exercise);
}

@riverpod
Stream<Set<String>> favoriteExerciseIds(Ref ref) {
  return ref.watch(exerciseRepositoryProvider).watchFavoriteIds();
}

@riverpod
Future<List<WorkoutTemplate>> workoutTemplates(Ref ref, {bool favoritesOnly = false}) async {
  final result = await ref.watch(workoutTemplateRepositoryProvider).getTemplates(favoritesOnly: favoritesOnly);
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<WorkoutTemplate> workoutTemplateById(Ref ref, String id) async {
  final result = await ref.watch(workoutTemplateRepositoryProvider).getTemplateById(id);
  return result.match((failure) => throw failure, (template) => template);
}

@riverpod
Future<List<WorkoutSession>> workoutHistory(Ref ref) async {
  final result = await ref.watch(workoutSessionRepositoryProvider).getHistory();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<int> completedWorkoutCount(Ref ref) async {
  final result = await ref.watch(workoutSessionRepositoryProvider).getCompletedWorkoutCount();
  return result.match((failure) => throw failure, (count) => count);
}

@riverpod
Future<WorkoutSession> workoutSessionById(Ref ref, String sessionId) async {
  final result = await ref.watch(workoutSessionRepositoryProvider).getSessionById(sessionId);
  return result.match((failure) => throw failure, (session) => session);
}
