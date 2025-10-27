import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:get/get.dart';

class LocationsController extends GetxController with LoaderMixin, MessagesMixin {
  final LocationsService _service;
  LocationsController({required LocationsService service}) : _service = service;

  late final ClientModel client;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <LocationModel>[].obs;

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
}

