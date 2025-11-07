import 'dart:typed_data';

import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildOrderReportPdf({
  required OrderModel order,
  ClientModel? client,
  LocationModel? location,
  EquipmentModel? equipment,
  List<CollaboratorModel> technicians = const [],
  Map<String, InventoryItemModel> materialCatalog = const {},
  String appName = 'AirSync',
}) async {
  final doc = pw.Document();
  final baseFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();
  final accent = PdfColor.fromHex('#1D3557');
  final lightFill = PdfColor.fromHex('#F3F6FB');
  final borderColor = PdfColor.fromHex('#D8DEE8');
  final dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final dateFormatter = DateFormat('dd/MM/yyyy');
  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final numberFormatter = NumberFormat.decimalPattern('pt_BR');

  String safe(String? value) {
    if (value == null) return '-';
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return dateTimeFormatter.format(value.toLocal());
  }

  String statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Agendada';
      case 'in_progress':
        return 'Em andamento';
      case 'done':
        return 'Concluida';
      case 'canceled':
        return 'Cancelada';
      default:
        return status;
    }
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
                'Relatorio da OS gerado em ${dateTimeFormatter.format(DateTime.now())}',
                style: pw.TextStyle(
                  font: baseFont,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.white, width: 0.6),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'OS ${order.id}',
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

  pw.Widget keyValueTable(List<List<String>> rows) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor, width: 0.4),
      ),
      child: pw.Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final background = index.isEven ? PdfColors.white : lightFill;
          final showDivider = index != rows.length - 1;
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: background,
              border:
                  showDivider
                      ? pw.Border(
                        bottom: pw.BorderSide(color: borderColor, width: 0.4),
                      )
                      : null,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(font: baseFont, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<String> splitLabel(String? value) {
    if (value == null) return const [];
    return value
        .split('-')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<pw.Widget> buildInfoSections() {
    final sections = <pw.Widget>[];

    void addSection(String title, List<List<String>> rows) {
      final filtered =
          rows
              .where(
                (row) =>
                    row.length >= 2 &&
                    row[1].trim().isNotEmpty &&
                    row[1].trim() != '-',
              )
              .toList();
      if (filtered.isEmpty) return;
      sections.add(sectionTitle(title));
      sections.add(keyValueTable(filtered));
      sections.add(pw.SizedBox(height: 18));
    }

    addSection('Resumo da OS', [
      ['Numero', order.id],
      ['Status', statusLabel(order.status)],
      ['Materiais (itens)', '${order.materials.length}'],
      ['Servicos (itens)', '${order.billing.items.length}'],
      ['Subtotal', currencyFormatter.format(order.billing.subtotal.toDouble())],
      [
        'Desconto',
        order.billing.discount == 0
            ? '-'
            : currencyFormatter.format(order.billing.discount.toDouble()),
      ],
      ['Total', currencyFormatter.format(order.billing.total.toDouble())],
    ]);

    if (client != null) {
      addSection('Cliente', [
        ['Nome', client.name],
        ['ID', client.id],
        ['Documento', safe(client.docNumber)],
        ['Emails', client.emails.isEmpty ? '-' : client.emails.join(', ')],
        ['Telefones', client.phones.isEmpty ? '-' : client.phones.join(', ')],
        if (client.tags.isNotEmpty) ['Tags', client.tags.join(', ')],
        if ((client.notes ?? '').trim().isNotEmpty)
          ['Notas', client.notes!.trim()],
        [
          'Assinatura coletada',
          order.customerSignatureUrl != null &&
                  order.customerSignatureUrl!.trim().isNotEmpty
              ? 'Sim'
              : 'Nao',
        ],
      ]);
    } else {
      addSection('Cliente', [
        ['Nome', safe(order.clientName)],
        ['ID', order.clientId],
        [
          'Assinatura coletada',
          order.customerSignatureUrl != null &&
                  order.customerSignatureUrl!.trim().isNotEmpty
              ? 'Sim'
              : 'Nao',
        ],
      ]);
    }

    if (location != null) {
      addSection('Local', [
        ['ID', location.id],
        ['Descricao', location.label],
        [
          'Endereco',
          [
            location.street ?? '',
            location.number ?? '',
            location.addressLine,
          ].where((part) => part.trim().isNotEmpty).join(', '),
        ],
        [
          'Cidade/Estado',
          [
            location.city ?? '',
            location.state ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' / '),
        ],
        if ((location.zip ?? '').trim().isNotEmpty)
          ['CEP', location.zip!.trim()],
        if ((location.notes ?? '').trim().isNotEmpty)
          ['Notas', location.notes!.trim()],
      ]);
    } else {
      final locationParts = splitLabel(order.locationLabel);
      final locationRows = <List<String>>[
        ['ID', order.locationId],
      ];
      if (locationParts.isNotEmpty) {
        locationRows.add(['Descricao', locationParts.first]);
        for (var i = 1; i < locationParts.length; i++) {
          locationRows.add(['Detalhe ${i + 1}', locationParts[i]]);
        }
      } else {
        locationRows.add(['Descricao', safe(order.locationLabel)]);
      }
      addSection('Local', locationRows);
    }

    if (equipment != null) {
      addSection('Equipamento', [
        ['ID', equipment.id],
        ['Descricao', safe(order.equipmentLabel)],
        if ((equipment.type ?? '').trim().isNotEmpty)
          ['Tipo', equipment.type!.trim()],
        if ((equipment.brand ?? '').trim().isNotEmpty)
          ['Marca', equipment.brand!.trim()],
        if ((equipment.model ?? '').trim().isNotEmpty)
          ['Modelo', equipment.model!.trim()],
        if ((equipment.room ?? '').trim().isNotEmpty)
          ['Ambiente', equipment.room!.trim()],
        if ((equipment.serial ?? '').trim().isNotEmpty)
          ['Numero de serie', equipment.serial!.trim()],
        if (equipment.btus != null)
          ['Capacidade (BTUs)', equipment.btus.toString()],
        if (equipment.installDate != null)
          [
            'Instalacao',
            dateFormatter.format(equipment.installDate!.toLocal()),
          ],
        if ((equipment.notes ?? '').trim().isNotEmpty)
          ['Notas', equipment.notes!.trim()],
      ]);
    } else {
      final equipmentRows = <List<String>>[];
      if (order.equipmentId != null && order.equipmentId!.isNotEmpty) {
        equipmentRows.add(['ID', order.equipmentId!]);
      }
      final equipmentParts = splitLabel(order.equipmentLabel);
      if (equipmentParts.isNotEmpty) {
        equipmentRows.add(['Descricao', equipmentParts.first]);
        for (var i = 1; i < equipmentParts.length; i++) {
          equipmentRows.add(['Detalhe ${i + 1}', equipmentParts[i]]);
        }
      } else {
        equipmentRows.add(['Descricao', safe(order.equipmentLabel)]);
      }
      addSection('Equipamento', equipmentRows);
    }

    if (technicians.isNotEmpty) {
      addSection(
        'Tecnicos responsaveis',
        List.generate(technicians.length, (index) {
          final tech = technicians[index];
          final roleLabel = () {
            switch (tech.role) {
              case CollaboratorRole.admin:
                return 'Administrador';
              case CollaboratorRole.manager:
                return 'Gerente';
              case CollaboratorRole.tech:
                return 'Tecnico';
              case CollaboratorRole.viewer:
                return 'Visualizador';
            }
          }();
          final email = safe(tech.email);
          final details = <String>[
            'Nome: ${safe(tech.name)}',
            'ID: ${tech.id}',
          ];
          if (email != '-') {
            details.add('Email: $email');
          }
          details.add('Perfil: $roleLabel');
          details.add('Status: ${tech.active ? 'Ativo' : 'Inativo'}');
          return ['Tecnico ${index + 1}', details.join('\n')];
        }),
      );
    }

    addSection('Datas e horarios', [
      ['Agendada para', formatDateTime(order.scheduledAt)],
      ['Iniciada em', formatDateTime(order.startedAt)],
      ['Concluida em', formatDateTime(order.finishedAt)],
      ['Criada em', formatDateTime(order.createdAt)],
      ['Atualizada em', formatDateTime(order.updatedAt)],
    ]);

    if ((order.notes ?? '').trim().isNotEmpty) {
      addSection('Observacoes', [
        ['Notas internas', order.notes!.trim()],
      ]);
    }
    if ((order.notes ?? '').trim().isNotEmpty) {
      addSection('Observações', [
        ['Notas internas', order.notes!.trim()],
      ]);
    }

    if (sections.isNotEmpty) {
      sections.removeLast(); // remove último Spacer
    }
    return sections;
  }

  pw.Widget materialsSection() {
    if (order.materials.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sectionTitle('Materiais utilizados'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor, width: 0.4),
            ),
            child: pw.Text(
              'Nenhum material informado.',
              style: pw.TextStyle(font: baseFont, fontSize: 10),
            ),
          ),
        ],
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#274B78')),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Material',
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
              'Detalhes',
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
              'Qtd',
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
              'Valor unitario',
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
              'Subtotal',
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
              'Reservado',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    ];

    for (var i = 0; i < order.materials.length; i++) {
      final material = order.materials[i];
      final item = materialCatalog[material.itemId];
      final nameCandidates =
          <String>[item?.description ?? '', material.itemName ?? '']
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
      final baseName = nameCandidates.isNotEmpty ? nameCandidates.first : '';
      final sku = (item?.sku ?? '').trim();
      final displayName = () {
        final buffer = StringBuffer();
        if (baseName.isNotEmpty) {
          buffer.write(baseName);
        }
        if (sku.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write('($sku)');
        }
        if (buffer.isEmpty) {
          buffer.write(sku.isNotEmpty ? sku : 'Item ${material.itemId}');
        }
        return buffer.toString();
      }();
      final details = <String>[];
      final seenDetailKeys = <String>{};
      void addDetail(String label, String? value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return;
        final key = '$label:$trimmed';
        if (seenDetailKeys.add(key)) {
          details.add('$label: $trimmed');
        }
      }

      addDetail('Nome', baseName);
      addDetail('SKU', sku);
      if (item != null) {
        addDetail('SKU', item.sku);
        final unitText = item.unit.trim();
        if (unitText.isNotEmpty) {
          addDetail('Unidade', unitText);
        }
        final unitLabel = unitText.isNotEmpty ? ' $unitText' : '';
        details.add(
          'Estoque atual: ${numberFormatter.format(item.quantity)}$unitLabel',
        );
        details.add(
          'Minimo: ${numberFormatter.format(item.minQuantity)}$unitLabel',
        );
        if (item.sellPrice != null) {
          details.add(
            'Preco de venda catalogo: '
            '${currencyFormatter.format(item.sellPrice)}',
          );
        }
        if (item.avgCost != null) {
          details.add('Custo medio: ${currencyFormatter.format(item.avgCost)}');
        }
        if (item.description.trim().isNotEmpty &&
            item.description.trim() != displayName) {
          addDetail('Descricao', item.description.trim());
        }
      } else if ((material.itemName ?? '').trim().isNotEmpty) {
        addDetail('Descricao', material.itemName!.trim());
      }
      addDetail(
        'Descricao',
        baseName.isNotEmpty ? baseName : 'Item ${material.itemId}',
      );
      if (material.deductedAt != null) {
        details.add(
          'Baixado em: ${dateTimeFormatter.format(material.deductedAt!.toLocal())}',
        );
      }
      final sourceUnitPrice = material.unitPrice ?? item?.sellPrice;
      final hasUnitPrice = sourceUnitPrice != null;
      final unitPrice = (sourceUnitPrice ?? 0).toDouble();
      final qty = material.qty.toDouble();
      final subtotal = hasUnitPrice ? qty * unitPrice : null;
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? PdfColors.white : lightFill,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                displayName,
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                details.join('\n'),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                numberFormatter.format(qty),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                hasUnitPrice ? currencyFormatter.format(unitPrice) : '-',
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                subtotal != null ? currencyFormatter.format(subtotal) : '-',
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                material.reserved ? 'Sim' : 'Nao',
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
        sectionTitle('Materiais utilizados'),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderColor, width: 0.4),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.3),
            children: rows,
          ),
        ),
      ],
    );
  }

  pw.Widget servicesSection() {
    if (order.billing.items.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          sectionTitle('Servicos'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor, width: 0.4),
            ),
            child: pw.Text(
              'Nenhum servico informado.',
              style: pw.TextStyle(font: baseFont, fontSize: 10),
            ),
          ),
        ],
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#274B78')),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Tipo',
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
              'Servico',
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
              'Quantidade',
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
              'Valor unitario',
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
              'Subtotal',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    ];

    for (var i = 0; i < order.billing.items.length; i++) {
      final item = order.billing.items[i];
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? PdfColors.white : lightFill,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                statusLabel(item.type),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                item.name,
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                item.qty.toString(),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                currencyFormatter.format(item.unitPrice),
                style: pw.TextStyle(font: baseFont, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                currencyFormatter.format(item.lineTotal),
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
        sectionTitle('Servicos'),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderColor, width: 0.4),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.3),
            children: rows,
          ),
        ),
      ],
    );
  }

  pw.Widget totalsSection() {
    final discount = order.billing.discount.toDouble();
    final subtotal = order.billing.subtotal.toDouble();
    final total = order.billing.total.toDouble();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        color: PdfColor.fromHex('#EEF2F8'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Subtotal',
                style: pw.TextStyle(font: baseFont, fontSize: 12),
              ),
              pw.Text(
                currencyFormatter.format(subtotal),
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Desconto',
                style: pw.TextStyle(font: baseFont, fontSize: 12),
              ),
              pw.Text(
                discount == 0 ? '-' : currencyFormatter.format(-discount.abs()),
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                currencyFormatter.format(total),
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final infoWidgets = buildInfoSections();

  doc.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
      build:
          (context) => [
            header(),
            pw.SizedBox(height: 20),
            ...infoWidgets,
            if (infoWidgets.isNotEmpty) pw.SizedBox(height: 18),
            materialsSection(),
            pw.SizedBox(height: 18),
            servicesSection(),
            totalsSection(),
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
