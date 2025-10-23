import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  CreateOrderUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, ServiceOrder>> call(Map<String, dynamic> data) => repository.create(data);
}
