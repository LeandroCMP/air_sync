import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/subscription_models.dart';
import 'package:air_sync/repositories/subscriptions/subscriptions_repository.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  SubscriptionsRepositoryImpl() : _api = Get.find<ApiClient>();

  final ApiClient _api;

  @override
  Future<SubscriptionCurrentModel> getCurrent() async {
    final res = await _api.dio.get('/v1/subscriptions/current');
    return SubscriptionCurrentModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<SubscriptionCurrentModel> updateCurrent({
    int? billingDay,
    String? billingContactName,
    String? billingContactEmail,
    String? billingContactPhone,
    String? preferredPaymentMethod,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'billingDay': billingDay,
      'billingContactName': billingContactName,
      'billingContactEmail': billingContactEmail,
      'billingContactPhone': billingContactPhone,
      'preferredPaymentMethod': preferredPaymentMethod,
      'notes': notes,
    }..removeWhere((key, value) => value == null || (value is String && value.trim().isEmpty));

    final res = await _api.dio.patch('/v1/subscriptions/current', data: payload);
    return SubscriptionCurrentModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<SubscriptionOverviewModel> overview() async {
    final res = await _api.dio.get('/v1/subscriptions/overview');
    return SubscriptionOverviewModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<SubscriptionAlertModel> alerts() async {
    final res = await _api.dio.get('/v1/subscriptions/alerts');
    return SubscriptionAlertModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<List<SubscriptionInvoiceModel>> invoices({String? status, DateTime? from, DateTime? to}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null && status != 'all') query['status'] = status;
      if (from != null) query['from'] = from.toIso8601String();
      if (to != null) query['to'] = to.toIso8601String();

      final res = await _api.dio.get(
        '/v1/subscriptions/invoices',
        queryParameters: query.isEmpty ? null : query,
      );
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => SubscriptionInvoiceModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } on DioException {
      return const [];
    }
  }

  @override
  Future<SubscriptionPaymentIntentResult> createPaymentIntent({
    required String invoiceId,
    required String method,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final payload = <String, dynamic>{
      'method': method,
      if (successUrl != null) 'successUrl': successUrl,
      if (cancelUrl != null) 'cancelUrl': cancelUrl,
    };
    final res = await _api.dio.post(
      '/v1/subscriptions/invoices/$invoiceId/intent',
      data: payload,
    );
    return SubscriptionPaymentIntentResult.fromMap(
      Map<String, dynamic>.from(res.data ?? {}),
    );
  }

  @override
  Future<SubscriptionInvoiceModel> payInvoice({
    required String invoiceId,
    String? note,
    DateTime? paidAt,
    double? amount,
  }) async {
    final payload = <String, dynamic>{
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (paidAt != null) 'paidAt': paidAt.toIso8601String(),
      if (amount != null) 'amount': amount,
    };
    final res = await _api.dio.post(
      '/v1/subscriptions/invoices/$invoiceId/pay',
      data: payload.isEmpty ? null : payload,
    );
    return SubscriptionInvoiceModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<SubscriptionInvoiceModel> negotiateInvoice({
    required String invoiceId,
    required String note,
    DateTime? newDueDate,
  }) async {
    final res = await _api.dio.post(
      '/v1/subscriptions/invoices/$invoiceId/negotiate',
      data: {
        'note': note,
        if (newDueDate != null) 'newDueDate': newDueDate.toIso8601String(),
      },
    );
    return SubscriptionInvoiceModel.fromMap(Map<String, dynamic>.from(res.data ?? {}));
  }

  @override
  Future<List<SubscriptionInvoiceModel>> createCarnet({bool payUpfront = false}) async {
    final payload = <String, dynamic>{'payUpfront': payUpfront};
    final res = await _api.dio.post(
      '/v1/subscriptions/invoices/carnet',
      data: payload,
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => SubscriptionInvoiceModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['invoices'] is List) {
      return (data['invoices'] as List)
          .whereType<Map>()
          .map((e) => SubscriptionInvoiceModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  @override
  Future<void> runBillingNow() async {
    await _api.dio.post('/v1/subscriptions/billing/run');
  }
}
