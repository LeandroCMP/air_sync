import 'dart:async';

import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FleetHistoryController extends GetxController {
  FleetHistoryController({required FleetService fleetService})
    : _fleetService = fleetService;

  final FleetService _fleetService;

  final events = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isPaginating = false.obs;
  final hasLoaded = false.obs;
  final hasMore = true.obs;

  final selectedTypes = <String>['check', 'fuel', 'maintenance'].obs;
  final yearFilter = DateTime.now().year.obs;
  final RxnInt monthFilter = RxnInt();

  final scrollController = ScrollController();

  late final String vehicleId;
  late final String vehicleTitle;

  static const int _limit = 30;
  int _page = 1;

  @override
  void onInit() {
    _resolveArguments();
    scrollController.addListener(_onScroll);
    super.onInit();
  }

  void _resolveArguments() {
    final args = Get.arguments;
    if (args is Map) {
      vehicleId = args['vehicleId']?.toString() ?? '';
      vehicleTitle = _preferredTitle(plate: args['title']?.toString());
      return;
    }
    if (args is FleetVehicleModel) {
      vehicleId = args.id;
      vehicleTitle = _preferredTitle(
        plate: args.plate,
        model: args.model,
      );
      return;
    }
    vehicleId = args?.toString() ?? '';
    vehicleTitle = 'Veículo';
  }

  @override
  Future<void> onReady() async {
    await loadInitial();
    super.onReady();
  }

  Future<void> loadInitial() async {
    _page = 1;
    hasMore.value = true;
    await _fetch(page: _page, replace: true);
    hasLoaded.value = true;
    _page = 2;
  }

  Future<void> refreshData() async {
    _page = 1;
    hasMore.value = true;
    await _fetch(page: 1, replace: true);
    _page = 2;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isPaginating.value || isLoading.value) return;
    await _fetch(page: _page, replace: false);
    if (hasMore.value) {
      _page += 1;
    }
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    if (vehicleId.isEmpty) return;
    if (replace) {
      isLoading.value = true;
    } else {
      isPaginating.value = true;
    }
    try {
      final range = _dateRange();
      final fetched = await _fleetService.listEvents(
        vehicleId,
        page: page,
        limit: _limit,
        types: selectedTypes.isEmpty ? null : selectedTypes.toList(),
        from: range.$1,
        to: range.$2,
        sort: 'at',
        order: 'desc',
      );
      if (replace) {
        events.assignAll(fetched);
      } else {
        events.addAll(fetched);
      }
      hasMore.value = fetched.length >= _limit;
    } finally {
      if (replace) {
        isLoading.value = false;
      } else {
        isPaginating.value = false;
      }
    }
  }

  (DateTime?, DateTime?) _dateRange() {
    final year = yearFilter.value;
    final month = monthFilter.value;
    if (month == null) {
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59);
      return (start, end);
    }
    final start = DateTime(year, month, 1);
    final end = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    return (start, end);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    final current = scrollController.position.pixels;
    if (max == 0) return;
    if (current >= max - 200) {
      unawaited(loadMore());
    }
  }

  Future<void> toggleType(String type) async {
    if (selectedTypes.contains(type)) {
      selectedTypes.remove(type);
    } else {
      selectedTypes.add(type);
    }
    selectedTypes.refresh();
    await refreshData();
  }

  Future<void> setYear(int year) async {
    if (yearFilter.value == year) return;
    yearFilter.value = year;
    await refreshData();
  }

  Future<void> setMonth(int? month) async {
    if (monthFilter.value == month) return;
    monthFilter.value = month;
    await refreshData();
  }

  Future<void> resetFilters() async {
    selectedTypes
      ..clear()
      ..addAll(['check', 'fuel', 'maintenance']);
    selectedTypes.refresh();
    yearFilter.value = DateTime.now().year;
    monthFilter.value = null;
    await refreshData();
  }

  List<int> get availableYears {
    final current = DateTime.now().year;
    return List.generate(6, (index) => current - index);
  }

  bool isTypeSelected(String type) => selectedTypes.contains(type);

  String _preferredTitle({String? plate, String? model}) {
    final normalizedPlate = (plate ?? '').trim();
    if (normalizedPlate.isNotEmpty) return normalizedPlate;
    final normalizedModel = (model ?? '').trim();
    if (normalizedModel.isNotEmpty) return normalizedModel;
    return 'Veículo';
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
