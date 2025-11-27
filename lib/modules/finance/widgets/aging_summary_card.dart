import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/modules/finance/widgets/finance_dashboard_card.dart';
import 'package:flutter/material.dart';

class AgingSummaryCard extends StatelessWidget {
  final String title;
  final FinanceDashboardAgingSummary data;
  final Color accent;
  final String Function(double value) currencyBuilder;

  const AgingSummaryCard({
    super.key,
    required this.title,
    required this.data,
    required this.accent,
    required this.currencyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.pending + data.overdue + data.upcoming;
    final description = total <= 0
        ? 'Sem valores pendentes para o período.'
        : 'Total ${currencyBuilder(total)}';

    return FinanceDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.themeTextMain,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: context.themeTextSubtle, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Pendentes',
            value: data.pending,
            total: total,
            barColor: accent,
            currencyBuilder: currencyBuilder,
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Em atraso',
            value: data.overdue,
            total: total,
            barColor: context.themeWarning,
            currencyBuilder: currencyBuilder,
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Próximos 15 dias',
            value: data.upcoming,
            total: total,
            barColor: context.themeInfo,
            currencyBuilder: currencyBuilder,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color barColor;
  final String Function(double value) currencyBuilder;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.total,
    required this.barColor,
    required this.currencyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio =
        total <= 0 ? 0 : (value / total).clamp(0.0, 1.0).toDouble();
    final double safeRatio = ratio.isNaN ? 0 : ratio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: context.themeTextSubtle)),
            Text(
              currencyBuilder(value),
              style: TextStyle(
                color: context.themeTextMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: safeRatio,
            backgroundColor: barColor.withValues(alpha: .2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

