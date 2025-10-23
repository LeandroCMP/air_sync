import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

class CreateClientUseCase {
  CreateClientUseCase(this.repository);

  final ClientsRepository repository;

  Future<Either<Failure, Client>> call(Map<String, dynamic> data) => repository.create(data);
}
