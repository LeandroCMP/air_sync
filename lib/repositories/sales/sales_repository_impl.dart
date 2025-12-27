import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/sale_model.dart';
import 'package:air_sync/repositories/sales/sales_repository.dart';
import 'package:get/get.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl() : _api = Get.find<ApiClient>();

  final ApiClient _api;

  @override
  Future<List<SaleModel>> list({String? status, String? search}) async {
    final query = <String, dynamic>{
      if ((status ?? '').isNotEmpty && status != 'all') 'status': status,
      if ((search ?? '').isNotEmpty) 'text': search,
    };
    final res = await _api.dio
        .get(
          '/v1/sales',
          queryParameters: query.isEmpty ? null : query,
        )
        .timeout(const Duration(seconds: 12));
    final data = res.data;
    List<Map<String, dynamic>> extract(dynamic payload) {
      if (payload is List) {
        return payload
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (payload is Map && payload['items'] is List) {
        return (payload['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    }

    final parsed = extract(data);
    return parsed.map(SaleModel.fromMap).toList();
  }

  @override
  Future<SaleModel> create({
    required String clientId,
    required String locationId,
    required List<SaleItemModel> items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    bool autoCreateOrder = false,
    Map<String, dynamic>? orderMeta,
  }) async {
    final payload = <String, dynamic>{
      'clientId': clientId.trim(),
      'locationId': locationId.trim(),
      'items': items.map((e) => e.toPayload()).toList(),
      'autoCreateOrder': autoCreateOrder,
      if (discount != null) 'discount': discount,
      if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      if (moveRequest != null && moveRequest.isNotEmpty) 'moveRequest': moveRequest,
      if (orderMeta != null && orderMeta.isNotEmpty) 'orderMeta': orderMeta,
    };
    final res = await _api.dio
        .post('/v1/sales', data: payload)
        .timeout(const Duration(seconds: 12));
    return SaleModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<SaleModel> update(
    String id, {
    String? clientId,
    String? locationId,
    List<SaleItemModel>? items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    bool? autoCreateOrder,
    Map<String, dynamic>? orderMeta,
  }) async {
    final payload = <String, dynamic>{};
    if (clientId != null) payload['clientId'] = clientId.trim();
    if (locationId != null) payload['locationId'] = locationId.trim();
    if (notes != null) payload['notes'] = notes.trim();
    if (autoCreateOrder != null) payload['autoCreateOrder'] = autoCreateOrder;
    if (discount != null) payload['discount'] = discount;
    if (moveRequest != null) payload['moveRequest'] = moveRequest;
    if (orderMeta != null && orderMeta.isNotEmpty) payload['orderMeta'] = orderMeta;
    if (items != null) {
      payload['items'] = items.map((e) => e.toPayload()).toList();
    }
    final res = await _api.dio
        .patch('/v1/sales/$id', data: payload)
        .timeout(const Duration(seconds: 12));
    return SaleModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<SaleModel> approve(String id, {bool forceOrder = false}) => _mutateStatus(
        id,
        'approve',
        payload: forceOrder ? {'forceOrder': true} : null,
      );

  @override
  Future<SaleModel> fulfill(String id, {DateTime? fulfilledAt}) =>
      _mutateStatus(
        id,
        'fulfill',
        payload: fulfilledAt == null
            ? null
            : {'fulfilledAt': fulfilledAt.toIso8601String()},
      );

  @override
  Future<SaleModel> cancel(String id, {String? reason}) => _mutateStatus(
        id,
        'cancel',
        payload:
            (reason == null || reason.trim().isEmpty) ? null : {'reason': reason.trim()},
      );

  Future<SaleModel> _mutateStatus(
    String id,
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    final res = await _api.dio
        .patch(
          '/v1/sales/$id/$action',
          data: payload == null || payload.isEmpty ? null : payload,
        )
        .timeout(const Duration(seconds: 12));
    return SaleModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<String> generateProposal(String id) async {
    final res = await _api.dio
        .post('/v1/sales/$id/insights/proposal')
        .timeout(const Duration(seconds: 20));
    return _extractInsightText(res.data);
  }

  @override
  Future<String> commercialAssistant(String id, String question) async {
    final payload = {'question': question};
    final res = await _api.dio
        .post('/v1/sales/$id/insights/chat', data: payload)
        .timeout(const Duration(seconds: 20));
    return _extractInsightText(res.data);
  }

  @override
  Future<SaleModel> launchOrderIfNeeded(
    String id, {
    bool force = false,
    Map<String, dynamic>? orderMeta,
  }) async {
    final payload = <String, dynamic>{
      if (force) 'forceOrder': true,
      if (orderMeta != null && orderMeta.isNotEmpty) 'orderMeta': orderMeta,
    };
    final res = await _api.dio
        .post(
          '/v1/sales/$id/order',
          data: payload.isEmpty ? null : payload,
        )
        .timeout(const Duration(seconds: 12));
    return SaleModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  String _extractInsightText(dynamic data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in [
        'text',
        'message',
        'answer',
        'proposal',
        'content',
      ]) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return map.values
          .whereType<String>()
          .firstWhere(
            (value) => value.trim().isNotEmpty,
            orElse: () => '',
          )
          .trim();
    }
    if (data is List) {
      final joined = data.whereType<String>().join('\n').trim();
      if (joined.isNotEmpty) return joined;
    }
    return data.toString();
  }
}
