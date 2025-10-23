import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/order.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<ServiceOrder>>> list({Map<String, dynamic>? filters});
  Future<Either<Failure, ServiceOrder>> getById(String id);
  Future<Either<Failure, ServiceOrder>> create(Map<String, dynamic> data);
  Future<Either<Failure, ServiceOrder>> update(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> start(String id);
  Future<Either<Failure, ServiceOrder>> finish(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> reserveMaterials(String id, List<Map<String, dynamic>> items);
  Future<Either<Failure, void>> deductMaterials(String id, List<Map<String, dynamic>> items);
}
