import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:get/get.dart';

class CostCentersController extends GetxController
    with LoaderMixin, MessagesMixin {
  CostCentersController({required CostCentersService service})
    : _service = service;

  final CostCentersService _service;

  final centers = <CostCenterModel>[].obs;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final RxString search = ''.obs;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await load();
    super.onReady();
  }

  List<CostCenterModel> get filteredCenters {
    final query = search.value.trim().toLowerCase();
    if (query.isEmpty) return centers;
    return centers
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              (c.code ?? '').toLowerCase().contains(query) ||
              (c.description ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final result = await _service.list(includeInactive: true);
      result.sort(
        (a, b) {
          if (a.active != b.active) {
            return a.active ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        },
      );
      centers.assignAll(result);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Centros de custo',
          message: 'Não foi possível carregar os centros de custo.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> save({
    String? id,
    required String name,
    String? code,
    String? description,
  }) async {
    isLoading(true);
    try {
      if (id == null) {
        await _service.create(name: name, code: code, description: description);
        message(
          MessageModel.success(
            title: 'Centros de custo',
            message: 'Centro criado com sucesso.',
          ),
        );
      } else {
        await _service.update(
          id,
          name: name,
          code: code,
          description: description,
        );
        message(
          MessageModel.success(
            title: 'Centros de custo',
            message: 'Centro atualizado com sucesso.',
          ),
        );
      }
      await load();
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Centros de custo',
          message: 'Não foi possível salvar as alterações.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleActive(CostCenterModel model) async {
    isLoading(true);
    try {
      await _service.setActive(model.id, !model.active);
      final idx = centers.indexWhere((element) => element.id == model.id);
      if (idx != -1) {
        centers[idx] = model.copyWith(active: !model.active);
        centers.refresh();
      }
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Centros de custo',
          message: 'Não foi possível atualizar o status.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }
}
