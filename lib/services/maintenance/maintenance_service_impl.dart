import 'package:air_sync/models/maintenance_reminder_model.dart';
import 'package:air_sync/models/maintenance_service_type.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository.dart';
import 'package:air_sync/services/maintenance/maintenance_service.dart';

class MaintenanceServiceImpl implements MaintenanceService {
  MaintenanceServiceImpl({required MaintenanceRepository repository})
    : _repository = repository;

  final MaintenanceRepository _repository;
  List<MaintenanceServiceType> _cache = const [];

  @override
  Future<List<MaintenanceServiceType>> listServiceTypes({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.isNotEmpty) return _cache;
    _cache = await _repository.listServiceTypes();
    return _cache;
  }

  @override
  List<MaintenanceServiceType> cachedServiceTypes() => _cache;

  @override
  Future<List<MaintenanceReminderModel>> listReminders({
    required String equipmentId,
    String status = 'pending',
  }) {
    return _repository.listReminders(
      equipmentId: equipmentId,
      status: status,
    );
  }
}
