import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/finance_transaction.dart';
import '../repositories/finance_repository.dart';

class GetFinanceTransactionsUseCase {
  GetFinanceTransactionsUseCase(this.repository);

  final FinanceRepository repository;

  Future<Either<Failure, List<FinanceTransaction>>> call({String? type}) => repository.list(type: type);
}
