import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryItem>>> list({String? text});
  Future<Either<Failure, InventoryItem>> getById(String id);
  Future<Either<Failure, void>> move(Map<String, dynamic> payload);
  Future<Either<Failure, List<InventoryItem>>> lowStock();
}
