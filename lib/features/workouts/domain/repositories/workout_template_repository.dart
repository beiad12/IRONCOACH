import '../../../../core/utils/result.dart';
import '../entities/workout_template.dart';

abstract interface class WorkoutTemplateRepository {
  Future<Result<List<WorkoutTemplate>>> getTemplates(
      {bool favoritesOnly = false});

  Future<Result<WorkoutTemplate>> getTemplateById(String id);

  Future<Result<WorkoutTemplate>> saveTemplate(WorkoutTemplate template);

  Future<Result<void>> deleteTemplate(String id);

  Future<Result<void>> toggleFavorite(String templateId,
      {required bool isFavorite});
}
