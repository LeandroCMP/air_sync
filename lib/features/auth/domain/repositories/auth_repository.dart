import 'package:dartz/dartz.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Session>> login(String email, String password, {String? tenantId});
  Future<Either<Failure, Session>> refresh(String refreshToken, String jti);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthUser>> me();
}
