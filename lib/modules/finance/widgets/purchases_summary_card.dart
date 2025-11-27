import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/modules/finance/widgets/finance_dashboard_card.dart';
import 'package:flutter/material.dart';

class PurchasesSummaryCard extends StatelessWidget {
  final FinanceDashboardPurchasesSummary data;
  final String Function(double value) currencyBuilder;

  const PurchasesSummaryCard({
    super.key,
    required this.data,
    required this.currencyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final totalOrders = (data.open + data.received + data.canceled).toDouble();
    final double receivedRatio = totalOrders <= 0
        ? 0
        : (data.received / totalOrders).clamp(0.0, 1.0).toDouble();
    final double safeRatio = receivedRatio.isNaN ? 0 : receivedRatio;

    return FinanceDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compras no período',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.themeTextMain,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor aberto ${currencyBuilder(data.openValue)}',
            style: TextStyle(
              color: context.themeTextSubtle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatusChip(
                label: 'Abertas',
                value: data.open,
                color: context.themeInfo,
              ),
              _StatusChip(
                label: 'Recebidas',
                value: data.received,
                color: context.themePrimary,
              ),
              _StatusChip(
                label: 'Canceladas',
                value: data.canceled,
                color: context.themeWarning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Recebimento',
            style: TextStyle(
              color: context.themeTextSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: safeRatio,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(context.themePrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextSubtle,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: context.themeTextMain,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

