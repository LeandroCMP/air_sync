import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'api_access_token';
  static const _refreshKey = 'api_refresh_token';
  static const _jtiKey = 'api_jti';

  String? _accessToken;
  String? _refreshToken;
  String? _jti;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get jti => _jti;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessKey);
    _refreshToken = prefs.getString(_refreshKey);
    _jti = prefs.getString(_jtiKey);
  }

  Future<void> save({required String access, required String refresh, String? jti}) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = access;
    _refreshToken = refresh;
    _jti = jti;
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (jti != null) {
      await prefs.setString(_jtiKey, jti);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = null;
    _refreshToken = null;
    _jti = null;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_jtiKey);
  }
}

