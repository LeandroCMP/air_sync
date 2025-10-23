import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dre_report.dart';
import '../entities/finance_transaction.dart';
import '../entities/kpi_report.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<FinanceTransaction>>> list({String? type});
  Future<Either<Failure, FinanceTransaction>> getById(String id);
  Future<Either<Failure, void>> pay(String id, Map<String, dynamic> payload);
  Future<Either<Failure, DreReport>> dre();
  Future<Either<Failure, List<FinanceKpiReport>>> kpis();
}
