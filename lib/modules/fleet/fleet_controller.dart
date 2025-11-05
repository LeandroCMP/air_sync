import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class FleetController extends GetxController with LoaderMixin, MessagesMixin {
  final FleetService _service;
  FleetController({required FleetService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <FleetVehicleModel>[].obs;
  final search = ''.obs;
  final sort = 'createdAt'.obs; // createdAt | odometer | plate
  final order = 'desc'.obs; // asc | desc

  @override
  Future<void> onInit() async {
    messageListener(message);
    await load();
    loaderListener(isLoading);
    super.onInit();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final list = await _service.list(text: search.value, sort: sort.value, order: order.value);
      items.assignAll(list);
    } finally {
      isLoading(false);
    }
  }

  Future<void> setSearch(String v) async {
    search.value = v;
    await load();
  }

  Future<void> setSort(String v) async {
    sort.value = v;
    await load();
  }

  Future<void> toggleOrder() async {
    order.value = order.value == 'asc' ? 'desc' : 'asc';
    await load();
  }

  Future<void> doCheck(FleetVehicleModel v, {int? odometer, int? fuelLevel, String? notes}) async {
    try {
      await _service.check(id: v.id, odometer: odometer, fuelLevel: fuelLevel, notes: notes);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Check registrado'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    }
  }

  Future<void> doFuel(FleetVehicleModel v, {required double liters, required double price, required String fuelType, int? odometer}) async {
    try {
      await _service.fuel(id: v.id, liters: liters, price: price, fuelType: fuelType, odometer: odometer);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Abastecimento registrado'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    }
  }

  Future<void> doMaintenance(FleetVehicleModel v, {required String description, double? cost, int? odometer}) async {
    try {
      await _service.maintenance(id: v.id, description: description, cost: cost, odometer: odometer);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Manutenção registrada'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    }
  }

  Future<void> createVehicle({required String plate, String? model, int? year, required int odometer}) async {
    isLoading(true);
    try {
      await _service.create(plate: plate, model: model, year: year, odometer: odometer);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Veículo cadastrado'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateVehicle(String id, {String? plate, String? model, int? year, int? odometer}) async {
    isLoading(true);
    try {
      await _service.update(id, plate: plate, model: model, year: year, odometer: odometer);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Veículo atualizado'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteVehicle(String id) async {
    isLoading(true);
    try {
      await _service.delete(id);
      await load();
      message(MessageModel.success(title: 'Frota', message: 'Veículo excluído'));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
    } finally {
      isLoading(false);
    }
  }

  String _mapError(Object e) {
    if (e is DioException) {
      try {
        final data = e.response?.data;
        if (data is Map && data['error'] is Map) {
          final err = Map<String, dynamic>.from(data['error']);
          final code = (err['code'] ?? '').toString();
          final msg = (err['message'] ?? '').toString();
          if (code.isNotEmpty && msg.isNotEmpty) return '$code: $msg';
          if (msg.isNotEmpty) return msg;
          if (code.isNotEmpty) return code;
        }
      } catch (_) {}
    }
    return e.toString();
  }
}
