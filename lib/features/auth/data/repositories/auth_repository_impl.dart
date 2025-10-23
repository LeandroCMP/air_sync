import 'package:dartz/dartz.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/auth/session_manager.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource, required SessionManager sessionManager})
      : _remoteDataSource = remoteDataSource,
        _sessionManager = sessionManager;

  final AuthRemoteDataSource _remoteDataSource;
  final SessionManager _sessionManager;

  @override
  Future<Either<Failure, Session>> login(String email, String password, {String? tenantId}) async {
    try {
      final data = await _remoteDataSource.login(email, password, tenantId: tenantId);
      final session = _mapSession(data);
      await _sessionManager.updateSession(session);
      return Right(session);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _sessionManager.clear();
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Session>> refresh(String refreshToken, String jti) async {
    try {
      final data = await _remoteDataSource.refresh(refreshToken, jti);
      final session = _mapSession(data);
      await _sessionManager.updateSession(session);
      return Right(session);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> me() async {
    try {
      final data = await _remoteDataSource.me();
      return Right(UserModel.fromJson(data));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  Session _mapSession(Map<String, dynamic> data) {
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return Session(
      userId: user.id,
      email: user.email,
      name: user.name,
      permissions: user.permissions,
      tenantId: data['tenantId'] as String? ?? _sessionManager.tenantId ?? '',
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      jti: data['jti'] as String,
    );
  }
}
