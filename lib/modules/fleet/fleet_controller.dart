import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FleetController extends GetxController with LoaderMixin, MessagesMixin {
  final FleetService _service;
  FleetController({required FleetService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <FleetVehicleModel>[].obs;
  final search = ''.obs;
  final searchController = TextEditingController();
  final sort = 'createdAt'.obs; // createdAt | odometer | plate
  final order = 'desc'.obs; // asc | desc
  final statusFilter = 'all'.obs; // all | recent | legacy | usage | model
  final insightsLoading = false.obs;

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
    final normalized = v.trim().toUpperCase();
    if (search.value == normalized) return;
    search.value = normalized;
    await load();
  }

  void clearSearch() {
    searchController.clear();
    setSearch('');
  }

  Future<void> setSort(String v) async {
    sort.value = v;
    await load();
  }

  Future<void> toggleOrder() async {
    order.value = order.value == 'asc' ? 'desc' : 'asc';
    await load();
  }

  void setStatusFilter(String value) {
    if (statusFilter.value == value) {
      statusFilter.value = 'all';
    } else {
      statusFilter.value = value;
    }
  }

  List<FleetVehicleModel> get filteredItems {
    final filter = statusFilter.value;
    switch (filter) {
      case 'recent':
        return items.where(_isRecent).toList();
      case 'legacy':
        return items.where(_isLegacy).toList();
      case 'usage':
        return items.where(_isHighUsage).toList();
      case 'model':
        return items.where(_hasModel).toList();
      default:
        return items;
    }
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
      final normalizedPlate = _normalizePlate(plate);
      final normalizedModel = _normalizeModel(model);
      await _service.create(
        plate: normalizedPlate,
        model: normalizedModel,
        year: year,
        odometer: odometer,
      );
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
      final normalizedPlate = plate == null ? null : _normalizePlate(plate);
      final normalizedModel = _normalizeModel(model);
      await _service.update(
        id,
        plate: normalizedPlate,
        model: normalizedModel,
        year: year,
        odometer: odometer,
      );
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

  Future<List<FleetInsightRecommendation>> fetchRecommendations() async {
    insightsLoading(true);
    try {
      final recs = await _service.getRecommendations();
      if (recs.isEmpty) {
        message(
          MessageModel.info(
            title: 'Frota',
            message: 'Nenhuma recomendação retornada',
          ),
        );
      }
      return recs;
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
      return [];
    } finally {
      insightsLoading(false);
    }
  }

  Future<FleetInsightChatResponse?> askAssistant(String question) async {
    if (question.trim().isEmpty) return null;
    insightsLoading(true);
    try {
      final response = await _service.askAi(question);
      return response;
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: _mapError(e)));
      return null;
    } finally {
      insightsLoading(false);
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

  bool _hasModel(FleetVehicleModel vehicle) =>
      (vehicle.model ?? '').trim().isNotEmpty;

  bool _isRecent(FleetVehicleModel vehicle) {
    final year = vehicle.year;
    if (year == null) return false;
    final threshold = DateTime.now().year - 5;
    return year >= threshold;
  }

  bool _isLegacy(FleetVehicleModel vehicle) {
    final year = vehicle.year;
    if (year == null) return false;
    final threshold = DateTime.now().year - 8;
    return year < threshold;
  }

  bool _isHighUsage(FleetVehicleModel vehicle) => vehicle.odometer >= 100000;

  String _normalizePlate(String value) => value.trim().toUpperCase();

  String? _normalizeModel(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.toUpperCase();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
