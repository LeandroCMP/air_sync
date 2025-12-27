import 'package:air_sync/models/sale_model.dart';
import 'package:air_sync/repositories/sales/sales_repository.dart';
import 'package:air_sync/services/sales/sales_service.dart';

class SalesServiceImpl implements SalesService {
  SalesServiceImpl({required SalesRepository repository}) : _repository = repository;

  final SalesRepository _repository;

  @override
  Future<SaleModel> approve(String id, {bool forceOrder = false}) =>
      _repository.approve(id, forceOrder: forceOrder);

  @override
  Future<SaleModel> cancel(String id, {String? reason}) =>
      _repository.cancel(id, reason: reason);

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
    final sale = await _repository.create(
      clientId: clientId,
      locationId: locationId,
      items: items,
      notes: notes,
      discount: discount,
      moveRequest: moveRequest,
      autoCreateOrder: autoCreateOrder,
    );
    if (!autoCreateOrder) {
      return sale;
    }
    final approved = await approve(sale.id, forceOrder: true);
    if ((approved.linkedOrderId ?? '').isNotEmpty) {
      return approved;
    }
    return launchOrderIfNeeded(approved.id, force: true, orderMeta: orderMeta);
  }

  @override
  Future<SaleModel> fulfill(String id, {DateTime? fulfilledAt}) =>
      _repository.fulfill(id, fulfilledAt: fulfilledAt);

  @override
  Future<List<SaleModel>> list({String? status, String? search}) =>
      _repository.list(status: status, search: search);

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
  }) =>
      _repository.update(
        id,
        clientId: clientId,
        locationId: locationId,
        items: items,
        discount: discount,
        notes: notes,
        moveRequest: moveRequest,
        autoCreateOrder: autoCreateOrder,
        orderMeta: orderMeta,
      );

  @override
  Future<String> generateProposal(String id) => _repository.generateProposal(id);

  @override
  Future<String> commercialAssistant(String id, String question) =>
      _repository.commercialAssistant(id, question);

  @override
  Future<SaleModel> launchOrderIfNeeded(
    String id, {
    bool force = false,
    Map<String, dynamic>? orderMeta,
  }) =>
      _repository.launchOrderIfNeeded(id, force: force, orderMeta: orderMeta);
}
