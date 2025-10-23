import 'package:flutter/material.dart';

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _statusColor(label, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(color: resolvedColor, fontWeight: FontWeight.bold)),
    );
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
