import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/entities/body_measurement.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/repositories/progress_repository.dart';

part 'progress_providers.g.dart';

@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) {
  return ProgressRepositoryImpl(ref.watch(supabaseClientProvider),
      () => ref.read(currentUserProvider)?.id);
}

@riverpod
Future<List<BodyMeasurement>> bodyMeasurements(Ref ref) async {
  final result = await ref.watch(progressRepositoryProvider).getMeasurements();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<List<ProgressPhoto>> progressPhotos(Ref ref) async {
  final result =
      await ref.watch(progressRepositoryProvider).getProgressPhotos();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<List<PersonalRecord>> personalRecords(Ref ref) async {
  final result =
      await ref.watch(progressRepositoryProvider).getPersonalRecords();
  return result.match((failure) => throw failure, (list) => list);
}
