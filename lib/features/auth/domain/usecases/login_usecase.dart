import 'package:dartz/dartz.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  LoginParams({required this.email, required this.password, this.tenantId});

  final String email;
  final String password;
  final String? tenantId;
}

class LoginUseCase {
  LoginUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, Session>> call(LoginParams params) {
    return repository.login(params.email, params.password, tenantId: params.tenantId);
  }
}
