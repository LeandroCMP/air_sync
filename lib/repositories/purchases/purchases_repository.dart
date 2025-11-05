import 'package:air_sync/models/purchase_model.dart';

abstract class PurchasesRepository {
  Future<List<PurchaseModel>> list();
  Future<PurchaseModel> create({
    required String supplierId,
    required List<PurchaseItemModel> items,
    String status = 'ordered',
    double? freight,
    String? notes,
  });
  Future<void> receive({required String id, DateTime? receivedAt});
  Future<PurchaseModel> update({
    required String id,
    String? supplierId,
    List<PurchaseItemModel>? items,
    String? status,
    double? freight,
    String? notes,
  });
}
