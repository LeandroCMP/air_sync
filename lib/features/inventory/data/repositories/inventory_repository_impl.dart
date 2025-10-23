import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_data_source.dart';
import '../datasources/inventory_remote_data_source.dart';
import '../models/inventory_item_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({required InventoryRemoteDataSource remoteDataSource, required InventoryLocalDataSource localDataSource})
      : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final InventoryRemoteDataSource _remoteDataSource;
  final InventoryLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, InventoryItem>> getById(String id) async {
    try {
      final local = await _localDataSource.getById(id);
      if (local != null) {
        return Right(local);
      }
      final json = await _remoteDataSource.fetchItem(id);
      final model = InventoryItemModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> list({String? text}) async {
    try {
      final jsonList = await _remoteDataSource.fetchItems(text: text);
      final items = jsonList.map(InventoryItemModel.fromJson).toList();
      for (final item in items) {
        await _localDataSource.upsert(item);
      }
      return Right(items);
    } catch (error) {
      final cache = await _localDataSource.fetchAll();
      if (cache.isNotEmpty) {
        return Right(cache);
      }
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> lowStock() async {
    try {
      final jsonList = await _remoteDataSource.lowStock();
      final items = jsonList.map(InventoryItemModel.fromJson).toList();
      return Right(items);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> move(Map<String, dynamic> payload) async {
    try {
      await _remoteDataSource.move(payload);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
