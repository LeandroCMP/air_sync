import 'package:air_sync/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> auth(String email, String password);
  Future<UserModel> me();
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? document,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> requestPasswordReset(String email);
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  });
  Future<void> logout();
}
