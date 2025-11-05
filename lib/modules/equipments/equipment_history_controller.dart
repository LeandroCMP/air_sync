import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/application/utils/pdf/equipment_report_pdf.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/services/locations/locations_service.dart';

class EquipmentHistoryController extends GetxController
    with LoaderMixin, MessagesMixin {
  final EquipmentsService _service;
  EquipmentHistoryController({required EquipmentsService service})
    : _service = service;

  late final String equipmentId;
  EquipmentModel? equipment;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <Map<String, dynamic>>[].obs;

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    final args = Get.arguments;
    if (args is Map) {
      equipmentId = (args['id'] ?? '').toString();
      final e = args['equipment'];
      if (e is EquipmentModel) equipment = e;
    } else if (args is String) {
      equipmentId = args;
    } else {
      equipmentId = args?.toString() ?? '';
    }
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
      final list = await _service.listHistory(equipmentId);
      items.assignAll(list);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Histórico',
          message: 'Falha ao carregar histórico',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  // Apenas leitura; eventos vêm das OS e ações de equipamento.
  Future<void> exportPdf() async {
    isLoading(true);
    try {
      final hist =
          items
              .map(
                (e) => MaintenanceModel.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList();
      final eq = equipment; // ideal: passar o EquipmentModel via arguments
      if (eq == null) {
        message(
          MessageModel.error(
            title: 'Relatório',
            message: 'Dados do equipamento indisponíveis',
          ),
        );
        return;
      }

      final authApp = Get.find<AuthServiceApplication>();
      final user = authApp.user.value;
      final companyName = user?.name;
      final locationLabel = await _tryLocationLabel(eq.clientId, eq.locationId);

      final bytes = await buildEquipmentReportPdf(
        equipment: eq,
        history: hist,
        appName: 'AirSync',
        companyName: companyName,
        locationLabel: locationLabel,
        clientName: null,
        companyDocument: user?.cpfOrCnpj,
        companyEmail: user?.email,
        companyPhone: user?.phone,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'equipamento_${eq.id}.pdf',
      );
    } catch (_) {
      message(
        MessageModel.error(title: 'Relatório', message: 'Falha ao gerar PDF'),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<String?> _tryLocationLabel(String clientId, String locationId) async {
    try {
      final locs = await Get.find<LocationsService>().listByClient(clientId);
      for (final l in locs) {
        if (l.id == locationId) return l.label;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
