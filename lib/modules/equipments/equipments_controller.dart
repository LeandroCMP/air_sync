import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class EquipmentsController extends GetxController
    with LoaderMixin, MessagesMixin {
  final EquipmentsService _service;
  EquipmentsController({required EquipmentsService service})
    : _service = service;

  late final ClientModel client;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <EquipmentModel>[].obs;
  final locationNames = <String, String>{}.obs;

  @override
  Future<void> onInit() async {
    messageListener(message);
    client = Get.arguments as ClientModel;
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await load();
    super.onReady();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final list = await _service.listByClient(client.id);
      items.assignAll(list);
      try {
        final locs = await Get.find<LocationsService>().listByClient(client.id);
        locationNames.assignAll({for (final l in locs) l.id: l.label});
      } catch (_) {}
    } finally {
      isLoading(false);
    }
  }

  String _apiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String && (nested['message'] as String).trim().isNotEmpty) {
        return (nested['message'] as String).trim();
      }
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if ((error.message ?? '').isNotEmpty) return error.message!;
  } else if (error is Exception) {
    final text = error.toString();
    if (text.trim().isNotEmpty) return text;
  }
  return fallback;
}


  Future<void> create({
    required String locationId,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    String? serial,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final e = await _service.create(
        clientId: client.id,
        locationId: locationId,
        room: room,
        brand: brand,
        model: model,
        type: type,
        btus: btus,
        serial: serial,
        notes: notes,
      );
      items.insert(0, e);
      message(
        MessageModel.success(
          title: 'Equipamentos',
          message: 'Equipamento cadastrado',
        ),
      );
    } catch (err) {
      message(MessageModel.error(title: 'Erro', message: _apiError(err, 'Falha ao executar a opera??o.')));
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateEquipment({
    required String id,
    String? locationId,
    String? brand,
    String? model,
    String? type,
    int? btus,
    String? room,
    String? serial,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.update(
        id: id,
        locationId: locationId,
        brand: brand,
        model: model,
        type: type,
        btus: btus,
        room: room,
        serial: serial,
        notes: notes,
      );
      final idx = items.indexWhere((e) => e.id == id);
      if (idx != -1) items[idx] = updated;
      message(
        MessageModel.success(
          title: 'Equipamentos',
          message: 'Equipamento atualizado',
        ),
      );
    } catch (err) {
      message(MessageModel.error(title: 'Erro', message: _apiError(err, 'Falha ao executar a opera??o.')));
    } finally {
      isLoading(false);
    }
  }

  Future<void> delete(String id) async {
    isLoading(true);
    try {
      await _service.delete(id);
      items.removeWhere((e) => e.id == id);
      message(
        MessageModel.success(
          title: 'Equipamentos',
          message: 'Equipamento removido',
        ),
      );
    } catch (err) {
      message(MessageModel.error(title: 'Erro', message: _apiError(err, 'Falha ao executar a opera??o.')));
    } finally {
      isLoading(false);
    }
  }

  Future<void> move({
    required String id,
    required String toLocationId,
    required String toRoom,
    String? toClientId,
    String? notes,
  }) async {
    isLoading(true);
    try {
      await _service.move(
        id,
        toLocationId: toLocationId,
        toRoom: toRoom,
        toClientId: toClientId,
        notes: notes,
      );
      await load();
      message(
        MessageModel.success(
          title: 'Equipamentos',
          message: 'Equipamento movido',
        ),
      );
    } catch (err) {
      message(MessageModel.error(title: 'Erro', message: _apiError(err, 'Falha ao executar a opera??o.')));
    } finally {
      isLoading(false);
    }
  }

  Future<void> replace({
    required String id,
    required Map<String, dynamic> newEquipment,
    String? notes,
  }) async {
    isLoading(true);
    try {
      await _service.replace(id, newEquipment: newEquipment, notes: notes);
      await load();
      message(
        MessageModel.success(
          title: 'Equipamentos',
          message: 'Equipamento substituído',
        ),
      );
    } catch (err) {
      message(MessageModel.error(title: 'Erro', message: _apiError(err, 'Falha ao executar a opera??o.')));
    } finally {
      isLoading(false);
    }
  }
}
