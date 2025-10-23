import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/auth/session_manager.dart';

class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._sessionManager);

  final SessionManager _sessionManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tenant = _sessionManager.tenantId ?? dotenv.env['TENANT_ID'];
    if (tenant != null && tenant.isNotEmpty) {
      options.headers['X-Tenant-Id'] = tenant;
    }
    handler.next(options);
  }
}
