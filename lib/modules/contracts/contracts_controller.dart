import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/contract_model.dart';
import 'package:air_sync/services/contracts/contracts_service.dart';
import 'package:get/get.dart';

class ContractsController extends GetxController with LoaderMixin, MessagesMixin {
  final ContractsService _service;
  ContractsController({required ContractsService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <ContractModel>[].obs;

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    await load();
    super.onInit();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final list = await _service.list();
      items.assignAll(list);
    } finally {
      isLoading(false);
    }
  }

  Future<void> create({
    required String clientId,
    required String planName,
    required int intervalMonths,
    required int slaHours,
    required double priceMonthly,
    required List<String> equipmentIds,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final c = await _service.create(
        clientId: clientId,
        planName: planName,
        intervalMonths: intervalMonths,
        slaHours: slaHours,
        priceMonthly: priceMonthly,
        equipmentIds: equipmentIds,
        notes: notes,
      );
      items.insert(0, c);
      message(MessageModel.info(title: 'Contrato criado', message: c.planName));
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: 'Falha ao criar contrato'));
    } finally {
      isLoading(false);
    }
  }
}


