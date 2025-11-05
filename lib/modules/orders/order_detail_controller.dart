import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:get/get.dart';

class OrderDetailController extends GetxController
    with LoaderMixin, MessagesMixin {
  OrderDetailController({required this.orderId, required OrdersService service})
    : _service = service;

  final String orderId;
  final OrdersService _service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final Rxn<OrderModel> order = Rxn<OrderModel>();

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

  Future<void> load() async {
    isLoading(true);
    try {
      final data = await _service.getById(orderId);
      order.value = data;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao carregar detalhes da OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> startOrder() async {
    isLoading(true);
    try {
      final updated = await _service.start(orderId);
      order.value = updated;
      message(MessageModel.success(title: 'OS', message: 'Ordem iniciada.'));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível iniciar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateOrder({
    String? status,
    DateTime? scheduledAt,
    List<String>? technicianIds,
    List<OrderChecklistInput>? checklist,
    List<OrderBillingItemInput>? billingItems,
    num? billingDiscount,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.update(
        orderId: orderId,
        status: status,
        scheduledAt: scheduledAt,
        technicianIds: technicianIds,
        checklist: checklist,
        billingItems: billingItems,
        billingDiscount: billingDiscount,
        notes: notes,
      );
      order.value = updated;
      message(MessageModel.success(title: 'OS', message: 'Dados atualizados.'));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível atualizar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> finishOrder({
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.finish(
        orderId: orderId,
        billingItems: billingItems,
        discount: discount,
        signatureBase64: signatureBase64,
        notes: notes,
      );
      order.value = updated;
      message(MessageModel.success(title: 'OS', message: 'Ordem finalizada.'));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível finalizar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> reserveMaterials(List<OrderMaterialInput> materials) async {
    if (materials.isEmpty) return;
    isLoading(true);
    try {
      await _service.reserveMaterials(orderId, materials);
      await load();
      message(
        MessageModel.success(
          title: 'Materiais',
          message: 'Materiais reservados.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível reservar materiais.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deductMaterials(List<OrderMaterialInput> materials) async {
    if (materials.isEmpty) return;
    isLoading(true);
    try {
      await _service.deductMaterials(orderId, materials);
      await load();
      message(
        MessageModel.success(
          title: 'Materiais',
          message: 'Materiais baixados.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível baixar materiais.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<String> uploadPhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final url = await _service.uploadPhoto(
        orderId: orderId,
        filename: filename,
        bytes: bytes,
      );
      await load();
      return url;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Upload',
          message: 'Não foi possível enviar a foto.',
        ),
      );
      rethrow;
    }
  }

  Future<String> uploadSignature(String base64) async {
    try {
      final url = await _service.uploadSignature(
        orderId: orderId,
        base64: base64,
      );
      await load();
      message(
        MessageModel.success(
          title: 'Assinatura',
          message: 'Assinatura anexada com sucesso.',
        ),
      );
      return url;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Assinatura',
          message: 'Não foi possível registrar a assinatura.',
        ),
      );
      rethrow;
    }
  }

  String pdfUrl({String type = 'report'}) =>
      _service.pdfUrl(orderId, type: type);
}
