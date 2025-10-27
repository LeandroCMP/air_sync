import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _baseUrlKey = 'api_base_url';
  static const _tenantIdKey = 'api_tenant_id';

  String _baseUrl = 'http://192.168.18.104:3001';
  String _tenantId = '';

  String get baseUrl => _baseUrl;
  String get tenantId => _tenantId;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _baseUrl;
    _tenantId = prefs.getString(_tenantIdKey) ?? _tenantId;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Future<void> setTenantId(String tenantId) async {
    _tenantId = tenantId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tenantIdKey, tenantId);
  }
}
