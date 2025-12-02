import 'package:air_sync/models/sale_model.dart';

abstract class SalesService {
  Future<List<SaleModel>> list({String? status, String? search});
  Future<SaleModel> create({
    required String clientId,
    required String locationId,
    required List<SaleItemModel> items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    bool autoCreateOrder = false,
  });
  Future<SaleModel> update(
    String id, {
    String? clientId,
    String? locationId,
    List<SaleItemModel>? items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    bool? autoCreateOrder,
  });
  Future<SaleModel> approve(String id, {bool forceOrder = false});
  Future<SaleModel> fulfill(String id, {DateTime? fulfilledAt});
  Future<SaleModel> cancel(String id, {String? reason});
  Future<String> generateProposal(String id);
  Future<String> commercialAssistant(String id, String question);
  Future<SaleModel> launchOrderIfNeeded(String id, {bool force = false});
}
