import 'package:air_sync/models/maintenance_reminder_model.dart';
import 'package:air_sync/models/maintenance_service_type.dart';

abstract class MaintenanceService {
  Future<List<MaintenanceServiceType>> listServiceTypes({bool forceRefresh = false});

  List<MaintenanceServiceType> cachedServiceTypes();

  Future<List<MaintenanceReminderModel>> listReminders({
    required String equipmentId,
    String status,
  });
}
