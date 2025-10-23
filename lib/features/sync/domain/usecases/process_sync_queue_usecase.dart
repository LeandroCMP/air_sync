import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/sync_repository.dart';

class ProcessSyncQueueUseCase {
  ProcessSyncQueueUseCase(this.repository);

  final SyncRepository repository;

  Future<Either<Failure, void>> call() => repository.processQueue();
}
