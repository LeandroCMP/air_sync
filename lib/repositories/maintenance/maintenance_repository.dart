import 'package:air_sync/models/maintenance_service_type.dart';
import 'package:air_sync/models/maintenance_reminder_model.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceServiceType>> listServiceTypes();

  Future<List<MaintenanceReminderModel>> listReminders({
    required String equipmentId,
    String status = 'pending',
  });
}
