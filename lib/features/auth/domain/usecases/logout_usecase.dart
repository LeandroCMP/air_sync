import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call() => repository.logout();
}
