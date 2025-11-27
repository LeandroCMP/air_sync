import 'package:air_sync/models/purchase_model.dart';

abstract class PurchasesService {
  Future<List<PurchaseModel>> list();
  Future<PurchaseModel> create({
    required String supplierId,
    required List<PurchaseItemModel> items,
    String status = 'ordered',
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  });
  Future<void> receive({required String id, DateTime? receivedAt});
  Future<PurchaseModel> update({
    required String id,
    String? supplierId,
    List<PurchaseItemModel>? items,
    String? status,
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  });

  Future<PurchaseModel> cancel({required String id, String? reason});

  Future<PurchaseModel> submit(String id, {String? notes});
  Future<PurchaseModel> approve(String id, {String? notes});
  Future<PurchaseModel> markAsOrdered(String id, {String? externalId});
}
