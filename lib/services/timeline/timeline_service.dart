import 'package:air_sync/models/timeline_entry_model.dart';

abstract class TimelineService {
  Future<List<TimelineEntryModel>> listByClient(String clientId);
  Future<TimelineEntryModel> create({
    required String clientId,
    required String type,
    required String text,
    DateTime? at,
    String? by,
  });
}


