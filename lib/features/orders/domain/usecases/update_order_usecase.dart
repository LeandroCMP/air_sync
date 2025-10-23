import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class UpdateOrderUseCase {
  UpdateOrderUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, ServiceOrder>> call(String id, Map<String, dynamic> data) => repository.update(id, data);
}
