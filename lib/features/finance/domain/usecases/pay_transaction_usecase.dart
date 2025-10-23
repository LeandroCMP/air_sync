import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/finance_repository.dart';

class PayTransactionUseCase {
  PayTransactionUseCase(this.repository);

  final FinanceRepository repository;

  Future<Either<Failure, void>> call(String id, Map<String, dynamic> payload) => repository.pay(id, payload);
}
