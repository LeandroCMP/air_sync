import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/repositories/auth/auth_repository.dart';
import 'package:air_sync/services/auth/auth_service.dart';

class AuthServiceImpl implements AuthService {
  final AuthRepository _authRepository;

  AuthServiceImpl({required AuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<UserModel> auth(String email, String password) =>
      _authRepository.auth(email, password);

  @override
  Future<void> logout() => _authRepository.logout();

  @override
  Future<void> resetPassword(String email) =>
      _authRepository.resetPassword(email);
}
