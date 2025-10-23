import 'package:equatable/equatable.dart';

class FinanceTransaction extends Equatable {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String type;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final String status;

  bool get isPaid => status == 'paid';

  @override
  List<Object?> get props => [id, type, description, amount, dueDate, status];
}
