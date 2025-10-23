import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class StartOrderUseCase {
  StartOrderUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, void>> call(String id) => repository.start(id);
}
