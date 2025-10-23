import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_database.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../datasources/clients_local_data_source.dart';
import '../datasources/clients_remote_data_source.dart';
import '../models/client_model.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  ClientsRepositoryImpl({required ClientsRemoteDataSource remoteDataSource, required ClientsLocalDataSource localDataSource})
      : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ClientsRemoteDataSource _remoteDataSource;
  final ClientsLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Client>> create(Map<String, dynamic> data) async {
    try {
      final json = await _remoteDataSource.createClient(data);
      final model = ClientModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remoteDataSource.deleteClient(id);
      await _localDataSource.delete(id);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Client>> getById(String id) async {
    try {
      final local = await _localDataSource.getById(id);
      if (local != null) {
        return Right(local);
      }
      final json = await _remoteDataSource.fetchClient(id);
      final model = ClientModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<Client>>> list({String? text}) async {
    try {
      final jsonList = await _remoteDataSource.fetchClients(text: text);
      final clients = jsonList.map(ClientModel.fromJson).toList();
      for (final client in clients) {
        await _localDataSource.upsert(client);
      }
      return Right(clients);
    } catch (error) {
      final cache = await _localDataSource.fetchAll();
      if (cache.isNotEmpty) {
        return Right(cache);
      }
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Client>> update(String id, Map<String, dynamic> data) async {
    try {
      final json = await _remoteDataSource.updateClient(id, data);
      final model = ClientModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
