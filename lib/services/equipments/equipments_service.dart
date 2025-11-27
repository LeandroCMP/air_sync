import 'package:air_sync/models/equipment_model.dart';

abstract class EquipmentsService {
  Future<List<EquipmentModel>> listByClient(String clientId);
  Future<List<EquipmentModel>> listBy(String clientId, {String? locationId});
  Future<EquipmentModel> create({
    required String clientId,
    required String locationId,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    DateTime? installDate,
    String? serial,
    String? notes,
  });
  Future<EquipmentModel> update({
    required String id,
    String? locationId,
    String? brand,
    String? model,
    String? type,
    int? btus,
    String? room,
    DateTime? installDate,
    String? serial,
    String? notes,
    bool includeNotes = false,
  });
  Future<void> delete(String id);

  // Manutenção
  Future<List<Map<String, dynamic>>> listHistory(String equipmentId);
  // Movimentação e substituição
  Future<void> move(
    String id, {
    required String toLocationId,
    required String toRoom,
    String? toClientId,
    String? notes,
  });
  Future<void> replace(
    String id, {
    required Map<String, dynamic> newEquipment,
    String? notes,
  });

  // Relatório PDF (URL)
}
