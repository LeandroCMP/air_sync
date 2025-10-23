import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sync_change.dart';

abstract class SyncRepository {
  Future<Either<Failure, List<SyncChange>>> pullChanges(DateTime? since, {String scope = 'all'});
  Future<Either<Failure, void>> processQueue();
}
