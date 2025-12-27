import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/maintenance_reminder_model.dart';
import 'package:air_sync/models/maintenance_service_type.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository.dart';
import 'package:get/get.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl() : _api = Get.find<ApiClient>();

  final ApiClient _api;

  @override
  Future<List<MaintenanceServiceType>> listServiceTypes() async {
    final res = await _api.dio.get('/v1/maintenance/service-types');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => MaintenanceServiceType.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  @override
  Future<List<MaintenanceReminderModel>> listReminders({
    required String equipmentId,
    String status = 'pending',
  }) async {
    final res = await _api.dio.get(
      '/v1/maintenance/reminders',
      queryParameters: {
        'equipmentId': equipmentId,
        'status': status,
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => MaintenanceReminderModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}
