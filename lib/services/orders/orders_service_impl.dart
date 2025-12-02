import 'package:air_sync/models/create_order_purchase_dto.dart';
import 'package:air_sync/models/order_costs_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';

class OrdersServiceImpl implements OrdersService {
  OrdersServiceImpl({
    required OrdersRepository repo,
    PurchasesService? purchasesService,
  })  : _repo = repo,
        _purchasesService = purchasesService;

  final OrdersRepository _repo;
  final PurchasesService? _purchasesService;

  @override
  Future<List<OrderModel>> list({
    DateTime? from,
    DateTime? to,
    String? status,
    String? technicianId,
  }) => _repo.list(
    from: from,
    to: to,
    status: status,
    technicianId: technicianId,
  );

  @override
  Future<OrderModel> getById(String id) => _repo.getById(id);

  @override
  Future<OrderModel> create({
    required String clientId,
    required String locationId,
    String? equipmentId,
    String? status,
    DateTime? scheduledAt,
    String? notes,
    List<String> technicianIds = const [],
    List<OrderChecklistInput> checklist = const [],
    List<OrderMaterialInput> materials = const [],
    List<OrderBillingItemInput> billingItems = const [],
    num billingDiscount = 0,
  }) => _repo.create(
    clientId: clientId,
    locationId: locationId,
    equipmentId: equipmentId,
    status: status,
    scheduledAt: scheduledAt,
    notes: notes,
    technicianIds: technicianIds,
    checklist: checklist,
    materials: materials,
    billingItems: billingItems,
    billingDiscount: billingDiscount,
  );

  @override
  Future<OrderModel> update({
    required String orderId,
    String? status,
    DateTime? scheduledAt,
    List<String>? technicianIds,
    List<OrderChecklistInput>? checklist,
    List<OrderBillingItemInput>? billingItems,
    num? billingDiscount,
    String? notes,
    String? clientId,
    String? locationId,
    String? equipmentId,
  }) => _repo.update(
    orderId: orderId,
    status: status,
    scheduledAt: scheduledAt,
    technicianIds: technicianIds,
    checklist: checklist,
    billingItems: billingItems,
    billingDiscount: billingDiscount,
    notes: notes,
    clientId: clientId,
    locationId: locationId,
    equipmentId: equipmentId,
  );

  @override
  Future<OrderModel> start(String orderId) => _repo.start(orderId);

  @override
  Future<OrderModel> finish({
    required String orderId,
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
    List<OrderPaymentInput> payments = const [],
  }) => _repo.finish(
    orderId: orderId,
    billingItems: billingItems,
    discount: discount,
    signatureBase64: signatureBase64,
    notes: notes,
    payments: payments,
  );

  @override
  Future<OrderModel> reschedule({
    required String orderId,
    required DateTime scheduledAt,
    String? notes,
  }) => _repo.reschedule(
    orderId: orderId,
    scheduledAt: scheduledAt,
    notes: notes,
  );

  @override
  Future<void> reserveMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) => _repo.reserveMaterials(orderId, materials);

  @override
  Future<void> deductMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) => _repo.deductMaterials(orderId, materials);

  @override
  Future<String> uploadPhoto({
    required String orderId,
    required String filename,
    required List<int> bytes,
  }) => _repo.uploadPhoto(orderId: orderId, filename: filename, bytes: bytes);

  @override
  Future<String> uploadSignature({
    required String orderId,
    required String base64,
  }) => _repo.uploadSignature(orderId: orderId, base64: base64);

  @override
  String pdfUrl(String orderId, {String type = 'report'}) =>
      _repo.pdfUrl(orderId, type: type);

  @override
  Future<void> delete(String orderId) => _repo.delete(orderId);

  @override
  Future<OrderCostsModel?> getCosts(String orderId) => _repo.getCosts(orderId);

  @override
  Future<PurchaseModel> createPurchaseFromOrder({
    required String orderId,
    required CreateOrderPurchaseDto dto,
  }) async {
    try {
      return await _repo.createPurchaseFromOrder(orderId: orderId, dto: dto);
    } catch (error) {
      final fallbackItems = dto.items;
      final purchasesService = _purchasesService;
      if (purchasesService != null &&
          fallbackItems != null &&
          fallbackItems.isNotEmpty) {
        return purchasesService.create(
          supplierId: dto.supplierId,
          items: dto.toPurchaseItems(orderId: orderId),
          freight: dto.freight,
          notes: dto.notes,
          paymentDueDate: dto.paymentDueDate,
        );
      }
      rethrow;
    }
  }

  @override
  Future<String> askTechnicalAssistant({
    required String orderId,
    required String question,
  }) => _repo.askTechnicalAssistant(
    orderId: orderId,
    question: question,
  );

  @override
  Future<String> generateCustomerSummary(String orderId) =>
      _repo.generateCustomerSummary(orderId);
}
