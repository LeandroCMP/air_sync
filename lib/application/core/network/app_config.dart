import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _baseUrlKey = 'api_base_url';
  static const _tenantIdKey = 'api_tenant_id';
  static const _stripeKeyPref = 'stripe_publishable_key';

  String _baseUrl = 'https://8ef9e873939b.ngrok-free.app';
  String _tenantId = '';
  String _stripePublishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51SV1zVJm3CNX7D18gGlAtEYKq35SFFVvd6JIr2QtwyoqY5G13dLkngi4eD2Z5Jrvl8ahpcu64Y0otP29Z4SeUBPU00b7nwD8cu',
  );

  String get baseUrl => _baseUrl;
  String get tenantId => _tenantId;
  String get stripePublishableKey => _stripePublishableKey;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _baseUrl;
    _tenantId = prefs.getString(_tenantIdKey) ?? _tenantId;
    _stripePublishableKey =
        prefs.getString(_stripeKeyPref) ?? _stripePublishableKey;
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

  Future<void> setStripePublishableKey(String key) async {
    _stripePublishableKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stripeKeyPref, key);
  }
}
