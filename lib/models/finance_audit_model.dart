class FinanceAuditIssue {
  final String id;
  final String reference;
  final String type; // order | purchase
  final String message;
  final double? deltaPercent;
  final DateTime? createdAt;

  const FinanceAuditIssue({
    required this.id,
    required this.reference,
    required this.type,
    required this.message,
    this.deltaPercent,
    this.createdAt,
  });

  factory FinanceAuditIssue.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const FinanceAuditIssue(
        id: '',
        reference: '',
        type: '',
        message: '',
      );
    }
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        if (value > 1e12) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is num) {
        final millis =
            value.abs() > 1e12 ? value.toInt() : (value.toDouble() * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return FinanceAuditIssue(
      id: (map['id'] ??
              map['referenceId'] ??
              map['orderId'] ??
              map['purchaseId'] ??
              '')
          .toString(),
      reference:
          (map['reference'] ?? map['orderNumber'] ?? map['purchaseNumber'] ?? '')
              .toString(),
      type: (map['type'] ?? map['kind'] ?? '').toString(),
      message: (map['message'] ?? map['description'] ?? '').toString(),
      deltaPercent: parseDouble(map['deltaPercent'] ?? map['delta']),
      createdAt: parseDate(map['createdAt'] ?? map['date']),
    );
  }
}

class FinanceAuditModel {
  final List<FinanceAuditIssue> orders;
  final List<FinanceAuditIssue> purchases;

  const FinanceAuditModel({
    required this.orders,
    required this.purchases,
  });

  factory FinanceAuditModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const FinanceAuditModel(orders: [], purchases: []);
    }
    List<FinanceAuditIssue> parseList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => FinanceAuditIssue.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    return FinanceAuditModel(
      orders: parseList(map['orders'] ?? map['orderIssues']),
      purchases: parseList(map['purchases'] ?? map['purchaseIssues']),
    );
  }
}

