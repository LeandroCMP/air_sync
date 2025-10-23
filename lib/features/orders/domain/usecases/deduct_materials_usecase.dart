import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class DeductMaterialsUseCase {
  DeductMaterialsUseCase(this.repository);

  final OrdersRepository repository;

  Future<Either<Failure, void>> call(String id, List<Map<String, dynamic>> items) => repository.deductMaterials(id, items);
}
