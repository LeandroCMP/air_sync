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
  Future<UserModel> fetchProfile() => _authRepository.me();

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? document,
  }) =>
      _authRepository.updateProfile(
        name: name,
        email: email,
        phone: phone,
        document: document,
      );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<void> requestPasswordReset(String email) =>
      _authRepository.requestPasswordReset(email);

  @override
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) =>
      _authRepository.resetPasswordWithToken(
        token: token,
        newPassword: newPassword,
      );

  @override
  Future<void> logout() => _authRepository.logout();
}
