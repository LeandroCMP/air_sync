import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrderDetailUseCase {
  GetOrderDetailUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, ServiceOrder>> call(String id) => repository.getById(id);
}
