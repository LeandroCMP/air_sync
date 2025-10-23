import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/clients_repository.dart';

class DeleteClientUseCase {
  DeleteClientUseCase(this.repository);

  final ClientsRepository repository;

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
