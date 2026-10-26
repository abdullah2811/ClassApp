import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../../core/storage/app_database.dart';

typedef SyncQueuePusher = Future<void> Function(SyncQueueEntry entry);

class OfflineSyncService {
  OfflineSyncService(
    this._database, {
    required SyncQueuePusher push,
    Connectivity? connectivity,
  })  : _push = push,
        _connectivity = connectivity ?? Connectivity();

  final AppDatabase _database;
  final SyncQueuePusher _push;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        unawaited(flushQueue());
      }
    });
  }

  Future<void> flushQueue() async {
    final pending = await (_database.select(_database.syncQueueEntries)
          ..where((entry) => entry.status.equals('pending')))
        .get();
    for (final entry in pending) {
      await (_database.update(_database.syncQueueEntries)
            ..where((row) => row.id.equals(entry.id)))
          .write(
        SyncQueueEntriesCompanion(
          status: const Value('syncing'),
          attempts: Value(entry.attempts + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
      try {
        await _push(entry);
        await (_database.delete(_database.syncQueueEntries)
              ..where((row) => row.id.equals(entry.id)))
            .go();
      } catch (error, stackTrace) {
        developer.log(
          'Failed to push queued ${entry.entityType} ${entry.id}',
          error: error,
          stackTrace: stackTrace,
          name: 'OfflineSyncService',
        );
        await (_database.update(_database.syncQueueEntries)
              ..where((row) => row.id.equals(entry.id)))
            .write(
          SyncQueueEntriesCompanion(
            status: const Value('failed'),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> enqueue({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) =>
      _database.into(_database.syncQueueEntries).insert(
            SyncQueueEntriesCompanion.insert(
              entityType: entityType,
              operation: operation,
              payload: jsonEncode(payload),
            ),
          );

  Future<void> dispose() async => _subscription?.cancel();
}
