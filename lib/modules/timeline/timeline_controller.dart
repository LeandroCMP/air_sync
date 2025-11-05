import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/timeline_entry_model.dart';
import 'package:air_sync/services/timeline/timeline_service.dart';
import 'package:get/get.dart';

class TimelineController extends GetxController with LoaderMixin, MessagesMixin {
  final TimelineService _service;
  TimelineController({required TimelineService service}) : _service = service;

  late final ClientModel client;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <TimelineEntryModel>[].obs;

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    client = Get.arguments as ClientModel;
    await load();
    super.onInit();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final list = await _service.listByClient(client.id);
      items.assignAll(list);
    } finally {
      isLoading(false);
    }
  }

  Future<void> addQuick(String type, String text) async {
    isLoading(true);
    try {
      final e = await _service.create(clientId: client.id, type: type, text: text);
      items.insert(0, e);
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: 'Falha ao adicionar evento'));
    } finally {
      isLoading(false);
    }
  }
}


