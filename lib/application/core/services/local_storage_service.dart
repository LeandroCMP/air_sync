import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _rememberMeKey = 'remember_me';
  static const _emailKey = 'email';

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> setEmail(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, value);
  }

  Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }
}
