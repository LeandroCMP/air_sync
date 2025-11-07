import 'package:air_sync/application/utils/pdf/order_report_pdf.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class OrderPdfViewerPage extends StatelessWidget {
  const OrderPdfViewerPage({
    super.key,
    required this.order,
    this.client,
    this.location,
    this.equipment,
    this.technicians = const [],
    this.materialCatalog = const {},
  });

  final OrderModel order;
  final ClientModel? client;
  final LocationModel? location;
  final EquipmentModel? equipment;
  final List<CollaboratorModel> technicians;
  final Map<String, InventoryItemModel> materialCatalog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF da OS')),
      body: PdfPreview(
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        build:
            (_) => buildOrderReportPdf(
              order: order,
              client: client,
              location: location,
              equipment: equipment,
              technicians: technicians,
              materialCatalog: materialCatalog,
            ),
      ),
    );
  }
}
