import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItemUseCase {
  GetInventoryItemUseCase(this.repository);

  final InventoryRepository repository;

  Future<Either<Failure, InventoryItem>> call(String id) => repository.getById(id);
}
