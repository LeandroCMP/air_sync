import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/repositories/purchases/purchases_repository.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';

class PurchasesServiceImpl implements PurchasesService {
  final PurchasesRepository _repo;
  PurchasesServiceImpl({required PurchasesRepository repo}) : _repo = repo;

  @override
  Future<PurchaseModel> create({
    required String supplierId,
    required List<PurchaseItemModel> items,
    String status = 'ordered',
    double? freight,
    String? notes,
  }) =>
      _repo.create(supplierId: supplierId, items: items, status: status, freight: freight, notes: notes);

  @override
  Future<List<PurchaseModel>> list() => _repo.list();

  @override
  Future<void> receive({required String id, DateTime? receivedAt}) =>
      _repo.receive(id: id, receivedAt: receivedAt);

  @override
  Future<PurchaseModel> update({
    required String id,
    String? supplierId,
    List<PurchaseItemModel>? items,
    String? status,
    double? freight,
    String? notes,
  }) => _repo.update(
        id: id,
        supplierId: supplierId,
        items: items,
        status: status,
        freight: freight,
        notes: notes,
      );
}
