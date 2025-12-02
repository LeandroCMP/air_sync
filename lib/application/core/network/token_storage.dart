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
    _accessToken = _sanitize(prefs.getString(_accessKey));
    _refreshToken = _sanitize(prefs.getString(_refreshKey));
    _jti = _sanitize(prefs.getString(_jtiKey));
  }

  Future<void> save({required String access, required String refresh, String? jti}) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = _sanitize(access);
    _refreshToken = _sanitize(refresh);
    _jti = _sanitize(jti);
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

  String? _sanitize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'null') return null;
    return trimmed;
  }
}
