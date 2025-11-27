import 'package:air_sync/models/create_order_purchase_dto.dart';
import 'package:air_sync/models/order_costs_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/models/purchase_model.dart';

abstract class OrdersService {
  Future<List<OrderModel>> list({
    DateTime? from,
    DateTime? to,
    String? status,
    String? technicianId,
  });

  Future<OrderModel> getById(String id);

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
    String? costCenterId,
  });

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
    String? costCenterId,
  });

  Future<OrderModel> start(String orderId);

  Future<OrderModel> finish({
    required String orderId,
    required List<OrderBillingItemInput> billingItems,
    num discount,
    String? signatureBase64,
    String? notes,
    List<OrderPaymentInput> payments,
  });

  Future<OrderModel> reschedule({
    required String orderId,
    required DateTime scheduledAt,
    String? notes,
  });

  Future<void> reserveMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  );

  Future<void> deductMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  );

  Future<String> uploadPhoto({
    required String orderId,
    required String filename,
    required List<int> bytes,
  });

  Future<String> uploadSignature({
    required String orderId,
    required String base64,
  });

  String pdfUrl(String orderId, {String type = 'report'});

  Future<void> delete(String orderId);

  Future<OrderCostsModel?> getCosts(String orderId);

  Future<PurchaseModel> createPurchaseFromOrder({
    required String orderId,
    required CreateOrderPurchaseDto dto,
  });

  Future<String> askTechnicalAssistant({
    required String orderId,
    required String question,
  });

  Future<String> generateCustomerSummary(String orderId);
}
