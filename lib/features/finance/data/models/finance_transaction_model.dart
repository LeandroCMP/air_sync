import 'dart:convert';

import '../../domain/entities/finance_transaction.dart';

class FinanceTransactionModel extends FinanceTransaction {
  FinanceTransactionModel({
    required super.id,
    required super.type,
    required super.description,
    required super.amount,
    required super.dueDate,
    required super.status,
  });

  factory FinanceTransactionModel.fromJson(Map<String, dynamic> json) => FinanceTransactionModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'receivable',
        description: json['description'] as String? ?? '',
        amount: (json['amount'] as num? ?? 0).toDouble(),
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'amount': amount,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
      };

  String toDatabase() => jsonEncode(toJson());

  factory FinanceTransactionModel.fromDatabase(Map<String, Object?> row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return FinanceTransactionModel.fromJson(payload);
  }
}
