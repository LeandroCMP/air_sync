import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

class MoveInventoryUseCase {
  MoveInventoryUseCase(this.repository);

  final InventoryRepository repository;

  Future<Either<Failure, void>> call(Map<String, dynamic> payload) => repository.move(payload);
}
