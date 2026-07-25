import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Cached workout sessions, written locally first and pushed to Supabase
/// by the [SyncEngine]. Mirrors the shape of the `workout_sessions` table.
class CachedWorkoutSessions extends Table {
  TextColumn get id => text()(); // uuid, client-generated
  TextColumn get userId => text()();
  TextColumn get templateId => text().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached individual set logs (weight/reps/RPE per exercise, per session).
class CachedWorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(CachedWorkoutSessions, #id)();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  RealColumn get rpe => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Read-through cache of the exercise library so the workout logger and
/// generator work fully offline.
class CachedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get primaryMuscle => text()();
  TextColumn get secondaryMusclesJson => text().withDefault(const Constant('[]'))();
  TextColumn get equipment => text().nullable()();
  TextColumn get difficulty => text()();
  TextColumn get instructions => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Locally cached favorite-exercise ids, so the exercise library can show
/// favorite state instantly offline. Kept in sync with `favorite_exercises`
/// via the generic [SyncQueueEntries] outbox.
class CachedFavoriteExercises extends Table {
  TextColumn get exerciseId => text()();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

class CachedFavoriteTemplates extends Table {
  TextColumn get templateId => text()();

  @override
  Set<Column> get primaryKey => {templateId};
}

/// Generic outbox for offline-first sync: every locally-created/updated
/// mutation across features gets an entry here. The [SyncEngine] drains
/// this table in order whenever connectivity is available.
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()(); // e.g. "workout_sessions"
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // insert | update | delete
  TextColumn get payloadJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(
  tables: [
    CachedWorkoutSessions,
    CachedWorkoutSets,
    CachedExercises,
    CachedFavoriteExercises,
    CachedFavoriteTemplates,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  Future<void> enqueueSync({
    required String entityTable,
    required String entityId,
    required String operation,
    required String payloadJson,
  }) {
    return into(syncQueueEntries).insert(
      SyncQueueEntriesCompanion.insert(
        entityTable: entityTable,
        entityId: entityId,
        operation: operation,
        payloadJson: payloadJson,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ironcoach.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
