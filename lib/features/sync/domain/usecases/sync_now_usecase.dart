import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sync_change.dart';
import '../repositories/sync_repository.dart';

class SyncNowUseCase {
  SyncNowUseCase(this.repository);

  final SyncRepository repository;

  Future<Either<Failure, List<SyncChange>>> call(DateTime? since, {String scope = 'all'}) => repository.pullChanges(since, scope: scope);
}
