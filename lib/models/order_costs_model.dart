class OrderCostMetric {
  const OrderCostMetric({
    required this.code,
    required this.label,
    required this.value,
    this.percent,
  });

  final String code;
  final String label;
  final double value;
  final double? percent;

  factory OrderCostMetric.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    double? parsePercent(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed == null) return null;

      if (parsed > 1) return parsed;
      if (parsed >= -1 && parsed <= 1) {
        // assume normalized (0-1)
        return parsed * 100;
      }
      return parsed;
    }

    String readLabel(dynamic value) {
      final raw = (value ?? '').toString().trim();
      if (raw.isNotEmpty) return raw;
      return 'Sem título';
    }

    return OrderCostMetric(
      code: (map['code'] ?? map['type'] ?? '').toString(),
      label: readLabel(map['label']),
      value: parseDouble(map['value'] ?? map['total'] ?? map['amount']),
      percent: parsePercent(map['percent'] ?? map['percentage']),
    );
  }
}

class OrderCostsModel {
  const OrderCostsModel({
    required this.orderId,
    required this.materialsCost,
    required this.purchasesCost,
    required this.overheadCost,
    required this.totalCost,
    required this.revenue,
    required this.marginValue,
    required this.marginPercent,
    this.blocks = const [],
  });

  final String orderId;
  final double materialsCost;
  final double purchasesCost;
  final double overheadCost;
  final double totalCost;
  final double revenue;
  final double marginValue;
  final double marginPercent;
  final List<OrderCostMetric> blocks;

  double get netResult => revenue - totalCost;

  List<OrderCostMetric> get resolvedBlocks {
    if (blocks.isNotEmpty) return blocks;
    return [
      OrderCostMetric(
        code: 'materials',
        label: 'Materiais',
        value: materialsCost,
        percent: _shareOf(materialsCost, totalCost),
      ),
      OrderCostMetric(
        code: 'purchases',
        label: 'Compras',
        value: purchasesCost,
        percent: _shareOf(purchasesCost, totalCost),
      ),
      OrderCostMetric(
        code: 'overhead',
        label: 'Indirectos',
        value: overheadCost,
        percent: _shareOf(overheadCost, totalCost),
      ),
    ];
  }

  static double? _shareOf(double value, double total) {
    if (total <= 0) return null;
    return (value / total) * 100;
  }

  factory OrderCostsModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final totals = map['totals'] as Map? ?? map;
    final blocksRaw =
        ((map['blocks'] ??
                    map['costBlocks'] ??
                    map['breakdown'] ??
                    map['items']) as List?) ??
        const [];

    double marginValue =
        parseDouble(
          totals['margin'] ??
              totals['marginValue'] ??
              totals['grossMargin'] ??
              map['margin'],
        );
    double revenue =
        parseDouble(totals['revenue'] ?? totals['billing'] ?? map['revenue']);
    double totalCost =
        parseDouble(totals['totalCost'] ?? totals['cost'] ?? map['totalCost']);
    if (marginValue == 0 && revenue > 0) {
      marginValue = revenue - totalCost;
    }
    double marginPercent =
        parseDouble(
          totals['marginPercent'] ?? totals['marginPct'] ?? map['marginPercent'],
        );
    if (marginPercent == 0 && marginValue != 0 && revenue > 0) {
      marginPercent = (marginValue / revenue) * 100;
    } else if (marginPercent > 0 && marginPercent <= 1) {
      marginPercent *= 100;
    }

    return OrderCostsModel(
      orderId: parseString(map['orderId']) ?? '',
      materialsCost:
          parseDouble(
            totals['materials'] ??
                totals['materialsCost'] ??
                map['materialsCost'],
          ),
      purchasesCost:
          parseDouble(
            totals['purchases'] ??
                totals['purchasesCost'] ??
                totals['buying'] ??
                map['purchasesCost'],
          ),
      overheadCost:
          parseDouble(
            totals['overhead'] ??
                totals['indirect'] ??
                totals['overheadCost'] ??
                map['overheadCost'],
          ),
      totalCost: totalCost,
      revenue: revenue,
      marginValue: marginValue,
      marginPercent: marginPercent,
      blocks:
          blocksRaw
              .whereType<Map>()
              .map(
                (element) => OrderCostMetric.fromMap(
                  Map<String, dynamic>.from(element),
                ),
              )
              .toList(),
    );
  }

  OrderCostsModel copyWith({
    String? orderId,
    double? materialsCost,
    double? purchasesCost,
    double? overheadCost,
    double? totalCost,
    double? revenue,
    double? marginValue,
    double? marginPercent,
    List<OrderCostMetric>? blocks,
  }) {
    return OrderCostsModel(
      orderId: orderId ?? this.orderId,
      materialsCost: materialsCost ?? this.materialsCost,
      purchasesCost: purchasesCost ?? this.purchasesCost,
      overheadCost: overheadCost ?? this.overheadCost,
      totalCost: totalCost ?? this.totalCost,
      revenue: revenue ?? this.revenue,
      marginValue: marginValue ?? this.marginValue,
      marginPercent: marginPercent ?? this.marginPercent,
      blocks: blocks ?? this.blocks,
    );
  }
}
