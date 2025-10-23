import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

class UpdateClientUseCase {
  UpdateClientUseCase(this.repository);

  final ClientsRepository repository;

  Future<Either<Failure, Client>> call(String id, Map<String, dynamic> data) => repository.update(id, data);
}
