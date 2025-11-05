import 'package:air_sync/application/utils/pdf/equipment_report_pdf.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class EquipmentPdfPreviewPage extends StatelessWidget {
  const EquipmentPdfPreviewPage({
    super.key,
    required this.equipment,
    required this.location,
    required this.client,
    required this.history,
  });

  final EquipmentModel equipment;
  final LocationModel location;
  final ClientModel client;
  final List<MaintenanceModel> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatorio do equipamento')),
      body: PdfPreview(
        canChangePageFormat: false,
        allowSharing: true,
        allowPrinting: true,
        build:
            (format) => buildEquipmentReportPdf(
              equipment: equipment,
              history: history,
              appName: 'AirSync',
              clientName: client.name,
              locationLabel: location.label,
              companyName: client.name,
              companyDocument: client.docNumber,
              companyEmail:
                  client.primaryEmail.isEmpty ? null : client.primaryEmail,
              companyPhone:
                  client.primaryPhone.isEmpty ? null : client.primaryPhone,
            ),
      ),
    );
  }
}
