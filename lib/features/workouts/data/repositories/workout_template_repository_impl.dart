import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/workout_template_repository.dart';

/// Templates are read/write directly against Supabase — unlike active
/// workout logging, editing a template is a low-frequency, non-blocking
/// action where requiring connectivity is an acceptable tradeoff for the
/// simpler implementation.
class WorkoutTemplateRepositoryImpl implements WorkoutTemplateRepository {
  WorkoutTemplateRepositoryImpl(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  static const _selectWithExercises =
      '*, workout_template_exercises(*, exercises(*))';

  @override
  Future<Result<List<WorkoutTemplate>>> getTemplates(
      {bool favoritesOnly = false}) async {
    try {
      final userId = _currentUserId();
      var query = _client
          .from(AppConstants.tableWorkoutTemplates)
          .select(_selectWithExercises);
      if (userId != null) {
        query =
            query.or('owner_id.eq.$userId,owner_id.is.null,is_public.eq.true');
      } else {
        query = query.or('owner_id.is.null,is_public.eq.true');
      }
      final rows = await query.order('created_at', ascending: false);

      final favoriteIds =
          userId == null ? <String>{} : await _fetchFavoriteIds(userId);
      var templates = List<Map<String, dynamic>>.from(rows as List)
          .map((r) => _mapTemplate(r, favoriteIds))
          .toList();

      if (favoritesOnly) {
        templates = templates.where((t) => t.isFavorite).toList();
      }
      return Right(templates);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<WorkoutTemplate>> getTemplateById(String id) async {
    try {
      final row = await _client
          .from(AppConstants.tableWorkoutTemplates)
          .select(_selectWithExercises)
          .eq('id', id)
          .single();
      final userId = _currentUserId();
      final favoriteIds =
          userId == null ? <String>{} : await _fetchFavoriteIds(userId);
      return Right(_mapTemplate(row, favoriteIds));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<WorkoutTemplate>> saveTemplate(WorkoutTemplate template) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());

    try {
      final templateRow = await _client
          .from(AppConstants.tableWorkoutTemplates)
          .upsert({
            if (template.id.isNotEmpty) 'id': template.id,
            'owner_id': userId,
            'name': template.name,
            'description': template.description,
            'goal': template.goal?.key,
            'difficulty': template.difficulty?.name,
            'estimated_duration_minutes': template.estimatedDurationMinutes,
            'is_ai_generated': template.isAiGenerated,
            'is_public': template.isPublic,
          })
          .select()
          .single();

      final templateId = templateRow['id'] as String;

      await _client
          .from(AppConstants.tableWorkoutTemplateExercises)
          .delete()
          .eq('template_id', templateId);
      if (template.exercises.isNotEmpty) {
        await _client.from(AppConstants.tableWorkoutTemplateExercises).insert([
          for (final te in template.exercises)
            {
              'template_id': templateId,
              'exercise_id': te.exercise.id,
              'position': te.position,
              'target_sets': te.targetSets,
              'target_reps_min': te.targetRepsMin,
              'target_reps_max': te.targetRepsMax,
              'target_rest_seconds': te.targetRestSeconds,
              'target_weight_kg': te.targetWeightKg,
              'notes': te.notes,
            },
        ]);
      }

      return getTemplateById(templateId);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTemplate(String id) async {
    try {
      await _client
          .from(AppConstants.tableWorkoutTemplates)
          .delete()
          .eq('id', id);
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String templateId,
      {required bool isFavorite}) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      if (isFavorite) {
        await _client
            .from(AppConstants.tableFavoriteTemplates)
            .upsert({'user_id': userId, 'template_id': templateId});
      } else {
        await _client
            .from(AppConstants.tableFavoriteTemplates)
            .delete()
            .eq('user_id', userId)
            .eq('template_id', templateId);
      }
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  Future<Set<String>> _fetchFavoriteIds(String userId) async {
    final rows = await _client
        .from(AppConstants.tableFavoriteTemplates)
        .select('template_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows as List)
        .map((r) => r['template_id'] as String)
        .toSet();
  }

  WorkoutTemplate _mapTemplate(
      Map<String, dynamic> row, Set<String> favoriteIds) {
    final rawExercises = List<Map<String, dynamic>>.from(
        row['workout_template_exercises'] as List? ?? []);
    rawExercises
        .sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    return WorkoutTemplate(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String?,
      name: row['name'] as String,
      description: row['description'] as String?,
      goal: WorkoutGoalX.fromKey(row['goal'] as String?),
      difficulty: row['difficulty'] == null
          ? null
          : ExerciseDifficultyX.fromKey(row['difficulty'] as String),
      estimatedDurationMinutes: row['estimated_duration_minutes'] as int?,
      isAiGenerated: row['is_ai_generated'] as bool? ?? false,
      isPublic: row['is_public'] as bool? ?? false,
      isFavorite: favoriteIds.contains(row['id']),
      exercises: rawExercises.map((te) {
        final exerciseRow = te['exercises'] as Map<String, dynamic>;
        return TemplateExercise(
          id: te['id'] as String,
          position: te['position'] as int,
          targetSets: te['target_sets'] as int? ?? 3,
          targetRepsMin: te['target_reps_min'] as int?,
          targetRepsMax: te['target_reps_max'] as int?,
          targetRestSeconds: te['target_rest_seconds'] as int? ?? 90,
          targetWeightKg: (te['target_weight_kg'] as num?)?.toDouble(),
          notes: te['notes'] as String?,
          exercise: Exercise(
            id: exerciseRow['id'] as String,
            name: exerciseRow['name'] as String,
            category:
                ExerciseCategoryX.fromKey(exerciseRow['category'] as String),
            primaryMuscle: exerciseRow['primary_muscle'] as String,
            secondaryMuscles: List<String>.from(
                exerciseRow['secondary_muscles'] as List? ?? []),
            difficulty: ExerciseDifficultyX.fromKey(
                exerciseRow['difficulty'] as String),
            equipment: exerciseRow['equipment'] as String?,
            mechanic:
                ExerciseMechanicX.fromKey(exerciseRow['mechanic'] as String?),
            instructions: exerciseRow['instructions'] as String?,
            videoUrl: exerciseRow['video_url'] as String?,
            imageUrl: exerciseRow['image_url'] as String?,
          ),
        );
      }).toList(),
    );
  }
}
