import 'package:dartz/dartz.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenParams {
  RefreshTokenParams({required this.refreshToken, required this.jti});

  final String refreshToken;
  final String jti;
}

class RefreshTokenUseCase {
  RefreshTokenUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, Session>> call(RefreshTokenParams params) {
    return repository.refresh(params.refreshToken, params.jti);
  }
}
