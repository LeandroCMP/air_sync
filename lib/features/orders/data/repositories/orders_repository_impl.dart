import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_data_source.dart';
import '../datasources/orders_remote_data_source.dart';
import '../models/order_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({required OrdersRemoteDataSource remoteDataSource, required OrdersLocalDataSource localDataSource})
      : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final OrdersRemoteDataSource _remoteDataSource;
  final OrdersLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, ServiceOrder>> create(Map<String, dynamic> data) async {
    try {
      final json = await _remoteDataSource.createOrder(data);
      final model = OrderModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> deductMaterials(String id, List<Map<String, dynamic>> items) async {
    try {
      await _remoteDataSource.deductMaterials(id, items);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ServiceOrder>> finish(String id, Map<String, dynamic> data) async {
    try {
      final json = await _remoteDataSource.finishOrder(id, data);
      final model = OrderModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ServiceOrder>> getById(String id) async {
    try {
      final local = await _localDataSource.getById(id);
      if (local != null) {
        return Right(local);
      }
      final json = await _remoteDataSource.fetchOrder(id);
      final model = OrderModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<ServiceOrder>>> list({Map<String, dynamic>? filters}) async {
    try {
      final jsonList = await _remoteDataSource.fetchOrders(filters: filters);
      final orders = jsonList.map(OrderModel.fromJson).toList();
      for (final order in orders) {
        await _localDataSource.upsert(order);
      }
      return Right(orders);
    } catch (error) {
      final cache = await _localDataSource.fetchAll();
      if (cache.isNotEmpty) {
        return Right(cache);
      }
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> reserveMaterials(String id, List<Map<String, dynamic>> items) async {
    try {
      await _remoteDataSource.reserveMaterials(id, items);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> start(String id) async {
    try {
      await _remoteDataSource.startOrder(id);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ServiceOrder>> update(String id, Map<String, dynamic> data) async {
    try {
      final json = await _remoteDataSource.updateOrder(id, data);
      final model = OrderModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
