import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/client.dart';

abstract class ClientsRepository {
  Future<Either<Failure, List<Client>>> list({String? text});
  Future<Either<Failure, Client>> getById(String id);
  Future<Either<Failure, Client>> create(Map<String, dynamic> data);
  Future<Either<Failure, Client>> update(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> delete(String id);
}
