class FinanceReconciliationPayment {
  final String id;
  final String reference;
  final String scope; // orders | purchases
  final String type;
  final double expectedAmount;
  final double paidAmount;
  final double difference;
  final String? status;
  final DateTime? dueDate;

  const FinanceReconciliationPayment({
    required this.id,
    required this.reference,
    required this.scope,
    required this.type,
    required this.expectedAmount,
    required this.paidAmount,
    required this.difference,
    this.status,
    this.dueDate,
  });

  bool get hasIssue => difference.abs() > 0.009;

  factory FinanceReconciliationPayment.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return FinanceReconciliationPayment(
      id: (map['id'] ?? '').toString(),
      reference: (map['reference'] ?? map['ref'] ?? '').toString(),
      scope: (map['scope'] ?? map['domain'] ?? 'all').toString(),
      type: (map['type'] ?? '').toString(),
      expectedAmount: parseDouble(map['expected'] ?? map['expectedAmount']),
      paidAmount: parseDouble(map['paid'] ?? map['paidAmount']),
      difference: parseDouble(map['difference'] ?? map['delta']),
      status: map['status']?.toString(),
      dueDate: parseDate(map['dueDate'] ?? map['due']),
    );
  }
}

class FinanceReconciliationIssue {
  final String id;
  final String type;
  final String message;
  final String suggestion;
  final String reference;
  final double? deltaAmount;

  const FinanceReconciliationIssue({
    required this.id,
    required this.type,
    required this.message,
    required this.suggestion,
    required this.reference,
    this.deltaAmount,
  });

  factory FinanceReconciliationIssue.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return FinanceReconciliationIssue(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      message: (map['message'] ?? map['issue'] ?? '').toString(),
      suggestion: (map['suggestion'] ?? map['action'] ?? '').toString(),
      reference: (map['reference'] ?? map['ref'] ?? '').toString(),
      deltaAmount: parseDouble(map['delta'] ?? map['difference']),
    );
  }
}
