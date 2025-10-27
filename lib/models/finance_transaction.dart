class FinanceTransactionModel {
  final String id;
  final String type; // receivable | payable
  final String status; // paid | pending
  final double amount;
  final double paidAmount;
  final DateTime? dueDate;
  final String description;
  final String? originOrderId;

  FinanceTransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.description,
    this.originOrderId,
  });

  factory FinanceTransactionModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final type = (map['type'] ?? '').toString();
    final status = (map['status'] ?? '').toString();
    final amount = (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? '0') ?? 0;
    final paid = (map['paidAmount'] is num) ? (map['paidAmount'] as num).toDouble() : double.tryParse(map['paidAmount']?.toString() ?? '0') ?? 0;
    DateTime? due;
    final dueRaw = map['dueDate'] ?? map['date'];
    if (dueRaw != null) {
      try { due = DateTime.parse(dueRaw.toString()); } catch (_) {}
    }
    final desc = (map['description'] ?? map['name'] ?? '').toString();
    final origin = (map['orderId'] ?? map['order']?['id'] ?? map['order']?['_id'])?.toString();
    return FinanceTransactionModel(
      id: id,
      type: type,
      status: status,
      amount: amount,
      paidAmount: paid,
      dueDate: due,
      description: desc,
      originOrderId: origin,
    );
  }
}

