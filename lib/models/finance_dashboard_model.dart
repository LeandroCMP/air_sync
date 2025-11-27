class FinanceDashboardPeriod {
  final DateTime? from;
  final DateTime? to;

  const FinanceDashboardPeriod({this.from, this.to});

  factory FinanceDashboardPeriod.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FinanceDashboardPeriod();
    return FinanceDashboardPeriod(
      from:
          map['from'] != null
              ? DateTime.tryParse(map['from'].toString())
              : null,
      to: map['to'] != null ? DateTime.tryParse(map['to'].toString()) : null,
    );
  }
}

class FinanceDashboardCards {
  final String month;
  final int ordersDone;
  final double revenue;
  final double avgTicket;
  final double grossCollected;
  final double netCollected;
  final double materialCost;
  final double purchaseCost;
  final double margin;

  const FinanceDashboardCards({
    required this.month,
    required this.ordersDone,
    required this.revenue,
    required this.avgTicket,
    required this.grossCollected,
    required this.netCollected,
    required this.materialCost,
    required this.purchaseCost,
    required this.margin,
  });

  factory FinanceDashboardCards.fromMap(Map<String, dynamic>? rawMap) {
    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double pickDouble(List<dynamic> candidates, {bool allowZero = false}) {
      for (final candidate in candidates) {
        final parsed = parseNullableDouble(candidate);
        if (parsed != null && (allowZero || parsed != 0)) {
          return parsed;
        }
      }
      return parseNullableDouble(
            candidates.isNotEmpty ? candidates.last : null,
          ) ??
          0;
    }

    int pickInt(List<dynamic> candidates) {
      for (final candidate in candidates) {
        final parsed = parseNullableInt(candidate);
        if (parsed != null && parsed != 0) {
          return parsed;
        }
      }
      return parseNullableInt(
            candidates.isNotEmpty ? candidates.last : null,
          ) ??
          0;
    }

    final map = rawMap ?? const <String, dynamic>{};
    final totals =
        map['totals'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['totals'])
            : null;
    final costs =
        map['costs'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['costs'])
            : null;
    final purchasesSummaryMap =
        map['purchases'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['purchases'])
            : null;

    double firstNonZeroValue(
      Map<String, dynamic>? source,
      List<String> keys,
    ) {
      if (source == null) return 0;
      for (final key in keys) {
        final parsed = parseNullableDouble(source[key]);
        if (parsed != null && parsed != 0) {
          return parsed;
        }
      }
      for (final key in keys) {
        final parsed = parseNullableDouble(source[key]);
        if (parsed != null) {
          return parsed;
        }
      }
      return 0;
    }

    final ordersDone = pickInt([
      map['ordersDone'],
      map['orders'],
      totals?['orders'],
    ]);

    final fees = pickDouble(
      [
        map['fees'],
        map['feesValue'],
        map['taxes'],
        totals?['fees'],
      ],
      allowZero: true,
    );

    final grossCollected = pickDouble([
      map['grossCollected'],
      map['revenue'],
      map['grossRevenue'],
      map['totalRevenue'],
      totals?['gross'],
      totals?['grossRevenue'],
    ]);

    var netCollected = pickDouble(
      [
        map['netCollected'],
        map['netRevenue'],
        map['liquidRevenue'],
        totals?['net'],
        totals?['liquid'],
      ],
      allowZero: true,
    );
    if (netCollected == 0 && grossCollected != 0) {
      netCollected = (grossCollected - fees).clamp(
        double.negativeInfinity,
        grossCollected,
      );
    }
    final netIsZero = netCollected == 0 && grossCollected == 0;

    final avgTicket = pickDouble(
      [
        map['avgTicket'],
        totals?['avgTicket'],
        ordersDone > 0 ? grossCollected / ordersDone : null,
      ],
      allowZero: true,
    );

    double aggregatedCosts = 0;
    double materialCostFromCosts = 0;
    double purchasesCostFromCosts = 0;
    double operationalCostFromCosts = 0;
    if (costs != null) {
      materialCostFromCosts = firstNonZeroValue(costs, [
        'materials',
        'materialsValue',
        'materialsCost',
        'materialCost',
      ]);
      purchasesCostFromCosts = firstNonZeroValue(costs, [
        'purchases',
        'purchasesValue',
        'purchasesCost',
        'purchaseCost',
        'buying',
      ]);
      operationalCostFromCosts = firstNonZeroValue(costs, [
        'operational',
        'operationalCost',
        'expenses',
        'overhead',
      ]);
      aggregatedCosts =
          materialCostFromCosts +
          purchasesCostFromCosts +
          operationalCostFromCosts;
      if (aggregatedCosts == 0) {
        aggregatedCosts =
            parseNullableDouble(costs['total']) ??
                parseNullableDouble(costs['totalCost']) ??
                0;
      }
    }

    final purchasesFromSummary = firstNonZeroValue(
      purchasesSummaryMap,
      [
        'totalValue',
        'receivedValue',
        'openValue',
        'value',
      ],
    );

    final purchasesFromTopLevel = pickDouble(
      [
        map['purchasesCost'],
        map['purchasesValue'],
        map['costsTotal'],
        map['totalCosts'],
      ],
      allowZero: true,
    );

    if (aggregatedCosts == 0) {
      aggregatedCosts = pickDouble(
        [
          map['costs'],
          map['costsValue'],
        ],
        allowZero: true,
      );
    }

    if (materialCostFromCosts == 0) {
      materialCostFromCosts = pickDouble(
        [
          map['materialsCost'],
          map['materialsValue'],
        ],
        allowZero: true,
      );
    }
    if (purchasesCostFromCosts == 0) {
      purchasesCostFromCosts = pickDouble(
        [
          map['purchasesCost'],
          map['purchasesValue'],
        ],
        allowZero: true,
      );
    }

    double materialCost = pickDouble(
      [
        map['materialCost'],
        map['materialsCost'],
        totals?['materialCost'],
        materialCostFromCosts,
      ],
      allowZero: true,
    );

    double purchaseCost = pickDouble(
      [
        map['purchaseCost'],
        map['purchasesCost'],
        map['purchasesValue'],
        map['purchases'],
        totals?['purchaseCost'],
        totals?['purchases'],
        purchasesFromSummary,
        purchasesCostFromCosts,
        purchasesFromTopLevel,
      ],
      allowZero: true,
    );

    if (materialCost == 0 && aggregatedCosts > 0) {
      final estimated =
          aggregatedCosts - purchasesCostFromCosts - operationalCostFromCosts;
      if (estimated > 0) {
        materialCost = estimated;
      }
    }

    if (purchaseCost == 0 && aggregatedCosts > 0) {
      final estimated =
          aggregatedCosts - materialCostFromCosts - operationalCostFromCosts;
      if (estimated > 0) {
        purchaseCost = estimated;
      }
    }

    double margin = pickDouble(
      [
        map['margin'],
        totals?['margin'],
      ],
      allowZero: true,
    );
    if (margin == 0 && !netIsZero && netCollected != 0) {
      margin = (netCollected - materialCost) / netCollected;
    } else if (margin.abs() > 1.5) {
      margin = margin / 100;
    }

    return FinanceDashboardCards(
      month: (map['month'] ?? map['label'] ?? '').toString(),
      ordersDone: ordersDone,
      revenue: grossCollected,
      avgTicket: avgTicket,
      grossCollected: grossCollected,
      netCollected: netCollected,
      materialCost: materialCost,
      purchaseCost: purchaseCost,
      margin: margin,
    );
  }
}

class FinanceDashboardPaymentMethod {
  final String method;
  final double gross;
  final double fees;
  final double net;

  const FinanceDashboardPaymentMethod({
    required this.method,
    required this.gross,
    required this.fees,
    required this.net,
  });

  factory FinanceDashboardPaymentMethod.fromMap(Map<String, dynamic> raw) {
    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    double pickDouble(List<dynamic> candidates) {
      for (final candidate in candidates) {
        final parsed = parseNullableDouble(candidate);
        if (parsed != null && parsed != 0) {
          return parsed;
        }
      }
      return parseNullableDouble(
            candidates.isNotEmpty ? candidates.last : null,
          ) ??
          0;
    }

    final method = (
      raw['method'] ??
      raw['name'] ??
      raw['paymentMethod'] ??
      raw['label'] ??
      ''
    ).toString();
    final fees = pickDouble([
      raw['fees'],
      raw['feesAmount'],
      raw['tax'],
      raw['taxes'],
    ]);
    var gross = pickDouble([
      raw['gross'],
      raw['grossAmount'],
      raw['total'],
      raw['bruto'],
      raw['value'],
      raw['amount'],
    ]);
    var net = pickDouble([
      raw['net'],
      raw['netAmount'],
      raw['liquid'],
      raw['liquido'],
      raw['liquidAmount'],
    ]);

    if (gross == 0 && net != 0) {
      gross = net + fees;
    } else if (net == 0 && gross != 0) {
      net = gross - fees;
    }

    return FinanceDashboardPaymentMethod(
      method: method,
      gross: gross,
      fees: fees,
      net: net,
    );
  }
}

class FinanceDashboardAgingSummary {
  final double pending;
  final double overdue;
  final double upcoming;

  const FinanceDashboardAgingSummary({
    required this.pending,
    required this.overdue,
    required this.upcoming,
  });

  factory FinanceDashboardAgingSummary.fromMap(Map<String, dynamic>? map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return FinanceDashboardAgingSummary(
      pending: parseDouble(map?['pending']),
      overdue: parseDouble(map?['overdue']),
      upcoming: parseDouble(map?['upcoming']),
    );
  }
}

class FinanceDashboardPurchasesSummary {
  final int open;
  final double openValue;
  final int received;
  final int canceled;

  const FinanceDashboardPurchasesSummary({
    required this.open,
    required this.openValue,
    required this.received,
    required this.canceled,
  });

  factory FinanceDashboardPurchasesSummary.fromMap(Map<String, dynamic>? map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return FinanceDashboardPurchasesSummary(
      open: parseInt(map?['open']),
      openValue: parseDouble(map?['openValue']),
      received: parseInt(map?['received']),
      canceled: parseInt(map?['canceled']),
    );
  }
}

class FinanceDashboardApprovalsSummary {
  final int pending;
  final int approved;
  final int ordered;
  final int received;

  const FinanceDashboardApprovalsSummary({
    this.pending = 0,
    this.approved = 0,
    this.ordered = 0,
    this.received = 0,
  });

  bool get hasData =>
      pending > 0 || approved > 0 || ordered > 0 || received > 0;

  factory FinanceDashboardApprovalsSummary.fromMap(
    Map<String, dynamic>? map,
  ) {
    if (map == null) return const FinanceDashboardApprovalsSummary();
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return FinanceDashboardApprovalsSummary(
      pending: parseInt(map['pending']),
      approved: parseInt(map['approved']),
      ordered: parseInt(map['ordered']),
      received: parseInt(map['received']),
    );
  }
}

class FinanceDashboardModel {
  final FinanceDashboardPeriod period;
  final FinanceDashboardCards cards;
  final List<FinanceDashboardPaymentMethod> paymentsByMethod;
  final FinanceDashboardAgingSummary receivables;
  final FinanceDashboardAgingSummary payables;
  final FinanceDashboardPurchasesSummary purchases;
  final FinanceDashboardApprovalsSummary purchaseApprovals;

  const FinanceDashboardModel({
    required this.period,
    required this.cards,
    required this.paymentsByMethod,
    required this.receivables,
    required this.payables,
    required this.purchases,
    required this.purchaseApprovals,
  });

  factory FinanceDashboardModel.fromMap(Map<String, dynamic> map) {
    final payments = <FinanceDashboardPaymentMethod>[];
    for (final entry in (map['paymentsByMethod'] as List?) ?? const []) {
      if (entry is Map) {
        payments.add(
          FinanceDashboardPaymentMethod.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        );
      }
    }

    return FinanceDashboardModel(
      period: FinanceDashboardPeriod.fromMap(
        map['period'] is Map ? Map<String, dynamic>.from(map['period']) : null,
      ),
      cards: FinanceDashboardCards.fromMap(
        map['cards'] is Map ? Map<String, dynamic>.from(map['cards']) : null,
      ),
      paymentsByMethod: payments,
      receivables: FinanceDashboardAgingSummary.fromMap(
        map['receivables'] is Map
            ? Map<String, dynamic>.from(map['receivables'])
            : null,
      ),
      payables: FinanceDashboardAgingSummary.fromMap(
        map['payables'] is Map
            ? Map<String, dynamic>.from(map['payables'])
            : null,
      ),
      purchases: FinanceDashboardPurchasesSummary.fromMap(
        map['purchases'] is Map
            ? Map<String, dynamic>.from(map['purchases'])
            : null,
      ),
      purchaseApprovals: FinanceDashboardApprovalsSummary.fromMap(
        map['purchaseApprovals'] is Map
            ? Map<String, dynamic>.from(map['purchaseApprovals'])
            : null,
      ),
    );
  }
}
