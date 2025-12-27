import 'dart:typed_data';

import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildEquipmentReportPdf({
  required EquipmentModel equipment,
  required List<MaintenanceModel> history,
  String appName = 'AirSync',
  String? clientName,
  String? locationLabel,
  String? companyName,
  String? companyDocument,
  String? companyEmail,
  String? companyPhone,
}) async {
  final doc = pw.Document();
  final baseFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();
  // Paleta alinhada ao app: verde principal e fundo escuro suave.
  final accent = PdfColor.fromHex('#0D9488');
  final lightFill = PdfColor.fromHex('#0F172A');
  final borderColor = PdfColor.fromHex('#1F2937');
  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  String safe(String? value) {
    if (value == null) return '-';
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  pw.Widget header() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: accent,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                appName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Gerado em ${dateTimeFormatter.format(DateTime.now())}',
                style: pw.TextStyle(
                  font: baseFont,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          if ((companyName ?? '').trim().isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.white, width: 0.6),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                companyName!.trim(),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 12, color: accent),
      ),
    );
  }

  pw.Widget infoTable(List<List<String>> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor, width: 0.4),
      ),
      child: pw.TableHelper.fromTextArray(
        cellAlignment: pw.Alignment.centerLeft,
        headerStyle: pw.TextStyle(
          font: boldFont,
          fontSize: 10,
          color: PdfColors.white,
        ),
        headerDecoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#274B78'),
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(8),
            topRight: pw.Radius.circular(8),
          ),
        ),
        cellStyle: pw.TextStyle(font: baseFont, fontSize: 10),
        rowDecoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
          ),
        ),
        oddRowDecoration: pw.BoxDecoration(color: lightFill),
        data: rows,
        headers: const ['Campo', 'Valor'],
        border: null,
        headerHeight: 24,
        cellHeight: 26,
      ),
    );
  }

  pw.Widget companyDetails() {
    final rows = <List<String>>[];
    if ((companyDocument ?? '').trim().isNotEmpty) {
      rows.add(['Documento', safe(companyDocument)]);
    }
    if ((companyEmail ?? '').trim().isNotEmpty) {
      rows.add(['Email', safe(companyEmail)]);
    }
    if ((companyPhone ?? '').trim().isNotEmpty) {
      rows.add(['Telefone', safe(companyPhone)]);
    }
    if (rows.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [sectionTitle('Dados da empresa'), infoTable(rows)],
    );
  }

  pw.Widget equipmentDetails() {
    final rows = <List<String>>[
      ['Cliente', safe(clientName)],
      ['Local', safe(locationLabel)],
      ['Ambiente', safe(equipment.room)],
      ['Marca', safe(equipment.brand)],
      ['Modelo', safe(equipment.model)],
      ['Tipo', safe(equipment.type)],
      ['BTUs', safe(equipment.btus?.toString())],
      ['Numero de serie', safe(equipment.serial)],
      [
        'Instalacao',
        equipment.installDate != null
            ? dateFormatter.format(equipment.installDate!)
            : '-',
      ],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        sectionTitle('Dados do equipamento'),
        infoTable(rows),
        pw.SizedBox(height: 12),
        pw.Text(
          'Observacoes',
          style: pw.TextStyle(font: boldFont, fontSize: 10, color: accent),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: lightFill,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            safe(equipment.notes),
            style: pw.TextStyle(font: baseFont, fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget historySection() {
    if (history.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sectionTitle('Historico'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor, width: 0.4),
            ),
            child: pw.Text(
              'Sem registros de historico.',
              style: pw.TextStyle(font: baseFont, fontSize: 10),
            ),
          ),
        ],
      );
    }

    final rowWidgets = <pw.TableRow>[];
    rowWidgets.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#274B78')),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Data/Hora',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Descricao',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    for (var i = 0; i < history.length; i++) {
      final item = history[i];
      final background = i.isEven ? PdfColors.white : lightFill;
      rowWidgets.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: background),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                dateTimeFormatter.format(item.date),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                safe(item.description),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        sectionTitle('Historico'),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderColor, width: 0.4),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.3),
            children: rowWidgets,
          ),
        ),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
      build:
          (context) => [
            header(),
            pw.SizedBox(height: 18),
            companyDetails(),
            if ((companyDocument ?? companyEmail ?? companyPhone ?? '')
                .trim()
                .isNotEmpty)
              pw.SizedBox(height: 18),
            equipmentDetails(),
            pw.SizedBox(height: 18),
            historySection(),
          ],
      footer:
          (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              appName,
              style: pw.TextStyle(font: baseFont, fontSize: 9),
            ),
          ),
    ),
  );

  return doc.save();
}
