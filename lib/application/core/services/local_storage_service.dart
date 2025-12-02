import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _rememberMeKey = 'remember_me';
  static const _emailKey = 'email';
  static const _activationPrefix = 'activation_verified_';
  static const _activationPendingPrefix = 'activation_pending_';
  static const _graceNoticePrefix = 'grace_notice_shown_';

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

  Future<void> setActivationVerified(String userId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_activationPrefix$userId', value);
  }

  Future<bool> isActivationVerified(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_activationPrefix$userId') ?? false;
  }

  Future<void> setActivationPending(String email, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_activationPendingPrefix$email', value);
  }

  Future<bool> isActivationPending(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_activationPendingPrefix$email') ?? false;
  }

  Future<void> setGraceNoticeShown(String userId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_graceNoticePrefix$userId', value);
  }

  Future<bool> isGraceNoticeShown(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_graceNoticePrefix$userId') ?? false;
  }
}
