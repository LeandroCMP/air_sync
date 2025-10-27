import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailController extends GetxController with LoaderMixin, MessagesMixin {
  final OrdersService _service;
  OrderDetailController({required OrdersService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  late OrderModel order;
  final RxList<Map<String, dynamic>> checklist = <Map<String, dynamic>>[].obs;
  final RxList<String> evidences = <String>[].obs; // nomes/URLs de arquivos enviados
  DateTime? startedAt;
  bool requireSignature = true;
  bool hasSignature = false;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    order = Get.arguments as OrderModel;
    super.onInit();
  }

  Future<void> startOrder() async {
    isLoading(true);
    try {
      await _service.start(order.id);
      startedAt = DateTime.now();
      message(MessageModel.success(title: 'OS', message: 'OS iniciada'));
    } catch (e) {
      if (e is dio.DioException) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401) {
          message(MessageModel.error(title: 'Sessão', message: 'Sessão expirada'));
        } else if (code == 403) {
          message(MessageModel.error(title: 'Permissão', message: 'Você não tem permissão para iniciar'));
        } else if (code == 422) {
          message(MessageModel.error(title: 'Regra de negócio', message: 'Operação não permitida'));
        } else {
          message(MessageModel.error(title: 'Erro', message: 'Falha ao iniciar OS'));
        }
      } else {
        message(MessageModel.error(title: 'Erro', message: 'Falha ao iniciar OS'));
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> reserveMaterials(List<Map<String, dynamic>> items) async {
    isLoading(true);
    try {
      await _service.reserveMaterials(order.id, items);
      message(MessageModel.success(title: 'Materiais', message: 'Materiais reservados'));
    } catch (e) {
      if (e is dio.DioException) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401) {
          message(MessageModel.error(title: 'Sessão', message: 'Sessão expirada'));
        } else if (code == 403) {
          message(MessageModel.error(title: 'Permissão', message: 'Você não tem permissão'));
        } else if (code == 409) {
          message(MessageModel.error(title: 'Estoque', message: 'Conflito de estoque (quantidade insuficiente)'));
        } else if (code == 422) {
          message(MessageModel.error(title: 'Regra de negócio', message: 'Operação não permitida'));
        } else {
          message(MessageModel.error(title: 'Erro', message: 'Falha ao reservar materiais'));
        }
      } else {
        message(MessageModel.error(title: 'Erro', message: 'Falha ao reservar materiais'));
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> finishOrder({required List<Map<String, dynamic>> materials, required List<Map<String, dynamic>> billingItems, double discount = 0}) async {
    // Regras: exigir início e assinatura (quando exigida)
    if (startedAt == null) {
      message(MessageModel.error(title: 'Timesheet', message: 'Inicie a OS antes de finalizar.'));
      return;
    }
    if (requireSignature && !hasSignature) {
      message(MessageModel.error(title: 'Assinatura', message: 'A assinatura do cliente é obrigatória.'));
      return;
    }
    final total = billingItems.fold<double>(0, (sum, e) => sum + (e['qty'] as num) * (e['unitPrice'] as num)) - discount;
    final payload = {
      'materials': materials,
      'billing': {
        'items': billingItems,
        'discount': discount,
        'total': total,
      },
      'checklist': checklist.toList(),
      if (startedAt != null)
        'timesheet': {
          'start': startedAt!.toUtc().toIso8601String(),
          'end': DateTime.now().toUtc().toIso8601String(),
        },
      if (evidences.isNotEmpty) 'evidences': evidences.toList(),
    };
    isLoading(true);
    try {
      final online = Get.find<ConnectivityService>().isOnline.value;
      if (!online) {
        await Get.find<QueueService>().enqueueFinishOrder(orderId: order.id, payload: payload);
        message(MessageModel.success(title: 'Offline', message: 'Finalização enfileirada'));
      } else {
        await _service.finish(orderId: order.id, payload: payload);
        message(MessageModel.success(title: 'OS', message: 'OS finalizada'));
      }
    } catch (e) {
      if (e is dio.DioException) {
        final code = e.response?.statusCode ?? 0;
        if (code == 401) {
          message(MessageModel.error(title: 'Sessão', message: 'Sessão expirada'));
        } else if (code == 403) {
          message(MessageModel.error(title: 'Permissão', message: 'Você não tem permissão'));
        } else if (code == 409) {
          message(MessageModel.error(title: 'Estoque', message: 'Conflito de estoque: ajuste as quantidades'));
        } else if (code == 422) {
          message(MessageModel.error(title: 'Regra de negócio', message: 'Assinatura/Timesheet/Materiais pendentes'));
        } else {
          message(MessageModel.error(title: 'Erro', message: 'Falha ao finalizar'));
        }
      }
      await Get.find<QueueService>().enqueueFinishOrder(orderId: order.id, payload: payload);
      message(MessageModel.error(title: 'Fila', message: 'Ação enfileirada para reenvio'));
    } finally {
      isLoading(false);
    }
  }

  Future<void> openPdf() async {
    final url = _service.pdfUrl(order.id);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      message(MessageModel.error(title: 'PDF', message: 'Não foi possível abrir o PDF'));
    }
  }

  Future<void> addChecklistItem(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    checklist.add({'text': t, 'checked': false});
  }

  void toggleChecklist(int index, bool value) {
    final item = Map<String, dynamic>.from(checklist[index]);
    item['checked'] = value;
    checklist[index] = item;
  }

  void removeChecklist(int index) => checklist.removeAt(index);

  Future<void> addEvidenceFromPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      final name = file.name;
      final uploaded = await _uploadBytes(name, bytes);
      evidences.add(uploaded);
      message(MessageModel.success(title: 'Upload', message: 'Arquivo enviado'));
    } catch (_) {
      message(MessageModel.error(title: 'Upload', message: 'Falha ao enviar arquivo'));
    }
  }

  Future<void> uploadSignatureBytes(List<int> bytes) async {
    try {
      final uploaded = await _uploadBytes('assinatura.png', bytes);
      evidences.add(uploaded);
      hasSignature = true;
      message(MessageModel.success(title: 'Assinatura', message: 'Assinatura anexada'));
    } catch (_) {
      message(MessageModel.error(title: 'Assinatura', message: 'Falha ao anexar assinatura'));
    }
  }

  Future<String> _uploadBytes(String filename, List<int> bytes) async {
    final api = Get.find<ApiClient>().dio;
    final form = dio.FormData.fromMap({'file': dio.MultipartFile.fromBytes(bytes, filename: filename)});
    final res = await api.post('/v1/files/upload', data: form, options: dio.Options(contentType: 'multipart/form-data'));
    final data = res.data;
    if (data is Map && data['name'] != null) return data['name'].toString();
    if (data is Map && data['url'] != null) return data['url'].toString();
    return filename;
  }
}


