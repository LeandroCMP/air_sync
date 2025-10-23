import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dre_report.dart';
import '../repositories/finance_repository.dart';

class GetDreUseCase {
  GetDreUseCase(this.repository);

  final FinanceRepository repository;

  Future<Either<Failure, DreReport>> call() => repository.dre();
}
