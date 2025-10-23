import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItemsUseCase {
  GetInventoryItemsUseCase(this.repository);

  final InventoryRepository repository;

  Future<Either<Failure, List<InventoryItem>>> call({String? text}) => repository.list(text: text);
}
