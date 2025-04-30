import 'package:air_sync/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> auth(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> logout();
}
