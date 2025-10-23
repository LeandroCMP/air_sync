import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase {
  GetOrdersUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, List<ServiceOrder>>> call({Map<String, dynamic>? filters}) {
    return repository.list(filters: filters);
  }
}
