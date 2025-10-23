import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_database.dart';
import '../../domain/entities/sync_change.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_remote_data_source.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({required SyncRemoteDataSource remoteDataSource, required LocalDatabase database})
      : _remoteDataSource = remoteDataSource,
        _database = database,
        _box = GetStorage();

  final SyncRemoteDataSource _remoteDataSource;
  final LocalDatabase _database;
  final GetStorage _box;

  static const _lastSyncKey = 'last_sync';

  @override
  Future<Either<Failure, List<SyncChange>>> pullChanges(DateTime? since, {String scope = 'all'}) async {
    try {
      final lastSync = since ?? _readLastSync();
      final jsonList = await _remoteDataSource.fetchChanges(lastSync, scope);
      final changes = jsonList
          .map((e) => SyncChange(
                entity: e['entity'] as String? ?? '',
                operation: e['operation'] as String? ?? 'upsert',
                payload: (e['payload'] as Map<String, dynamic>? ?? <String, dynamic>{}),
              ))
          .toList();
      _box.write(_lastSyncKey, DateTime.now().toIso8601String());
      return Right(changes);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> processQueue() async {
    try {
      final queue = await _database.fetchSyncQueue();
      for (final task in queue) {
        final id = task['id'] as int;
        final endpoint = task['endpoint'] as String;
        final method = task['method'] as String;
        final body = task['body'] != null ? GetUtils.jsonDecode(task['body'] as String) as Map<String, dynamic> : null;
        final headers = task['headers'] != null ? GetUtils.jsonDecode(task['headers'] as String) as Map<String, dynamic> : null;
        await _remoteDataSource.replay(endpoint, method, body, headers);
        await _database.removeSyncItem(id);
      }
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  DateTime? _readLastSync() {
    final value = _box.read<String?>(_lastSyncKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
