import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../local_db/app_database.dart';
import '../local_db/database_provider.dart';
import '../network/supabase_client_provider.dart';

part 'sync_engine.g.dart';

/// Drains the offline outbox ([SyncQueueEntries]) against Supabase whenever
/// connectivity returns, and periodically as a safety net.
///
/// This is the single writer path for offline-first mutations: feature
/// repositories write to the local drift cache immediately (so the UI is
/// instant and works offline), enqueue a [SyncQueueEntries] row describing
/// the mutation, and this engine is responsible for eventually reconciling
/// that row with Postgres — retrying with backoff on failure and leaving
/// the row in place (with `lastError` set) if retries are exhausted, so
/// nothing is silently dropped.
class SyncEngine {
  SyncEngine(this._db, this._supabase, this._logger) {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(syncNow());
      }
    });
    _periodicTimer =
        Timer.periodic(AppConstants.syncInterval, (_) => unawaited(syncNow()));
  }

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final Logger _logger;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await _db.select(_db.syncQueueEntries).get();
      for (final entry in pending) {
        await _process(entry);
      }
    } catch (e, st) {
      _logger.e('Sync run failed', error: e, stackTrace: st);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _process(SyncQueueEntry entry) async {
    if (entry.retryCount >= AppConstants.syncMaxRetries) return;

    try {
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      switch (entry.operation) {
        case 'insert':
        case 'update':
          await _supabase.from(entry.entityTable).upsert(payload);
        case 'delete':
          await _supabase
              .from(entry.entityTable)
              .delete()
              .eq('id', entry.entityId);
      }
      await (_db.delete(_db.syncQueueEntries)
            ..where((t) => t.id.equals(entry.id)))
          .go();
      await _clearDirtyFlag(entry);
    } catch (e) {
      _logger.w('Sync failed for ${entry.entityTable}/${entry.entityId}: $e');
      await (_db.update(_db.syncQueueEntries)
            ..where((t) => t.id.equals(entry.id)))
          .write(
        SyncQueueEntriesCompanion(
          retryCount: Value(entry.retryCount + 1),
          lastError: Value(e.toString()),
        ),
      );
    }
  }

  Future<void> _clearDirtyFlag(SyncQueueEntry entry) async {
    switch (entry.entityTable) {
      case AppConstants.tableWorkoutSessions:
        await (_db.update(_db.cachedWorkoutSessions)
              ..where((t) => t.id.equals(entry.entityId)))
            .write(const CachedWorkoutSessionsCompanion(isDirty: Value(false)));
      case AppConstants.tableWorkoutSets:
        await (_db.update(_db.cachedWorkoutSets)
              ..where((t) => t.id.equals(entry.entityId)))
            .write(const CachedWorkoutSetsCompanion(isDirty: Value(false)));
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }
}

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
    Logger(),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}
