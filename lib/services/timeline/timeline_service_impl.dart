import 'package:air_sync/models/timeline_entry_model.dart';
import 'package:air_sync/repositories/timeline/timeline_repository.dart';
import 'package:air_sync/services/timeline/timeline_service.dart';

class TimelineServiceImpl implements TimelineService {
  final TimelineRepository _repo;
  TimelineServiceImpl({required TimelineRepository repo}) : _repo = repo;

  @override
  Future<TimelineEntryModel> create({
    required String clientId,
    required String type,
    required String text,
    DateTime? at,
    String? by,
  }) =>
      _repo.create(clientId: clientId, type: type, text: text, at: at, by: by);

  @override
  Future<List<TimelineEntryModel>> listByClient(String clientId) => _repo.listByClient(clientId);
}


