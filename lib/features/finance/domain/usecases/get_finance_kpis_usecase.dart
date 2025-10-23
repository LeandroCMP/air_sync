import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/kpi_report.dart';
import '../repositories/finance_repository.dart';

class GetFinanceKpisUseCase {
  GetFinanceKpisUseCase(this.repository);

  final FinanceRepository repository;

  Future<Either<Failure, List<FinanceKpiReport>>> call() => repository.kpis();
}
