import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

class GetClientsUseCase {
  GetClientsUseCase(this.repository);

  final ClientsRepository repository;

  Future<Either<Failure, List<Client>>> call({String? text}) => repository.list(text: text);
}
