import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/finance/widgets/finance_dashboard_card.dart';
import 'package:flutter/material.dart';

class SummaryGridItem {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color color;

  const SummaryGridItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.helper,
  });
}

class SummaryGrid extends StatelessWidget {
  final List<SummaryGridItem> items;

  const SummaryGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        int columns = 1;
        if (maxWidth >= 1100) {
          columns = 5;
        } else if (maxWidth >= 880) {
          columns = 4;
        } else if (maxWidth >= 640) {
          columns = 3;
        } else if (maxWidth >= 420) {
          columns = 2;
        }
        final spacing = 14.0;
        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: FinanceDashboardCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: _SummaryTile(item: item),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final SummaryGridItem item;
  const _SummaryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final circleBg = item.color.withValues(alpha: .16);
    final helperStyle = textTheme.bodySmall?.copyWith(
      color: context.themeTextSubtle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: circleBg,
          foregroundColor: item.color,
          child: Icon(item.icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: helperStyle,
              ),
              const SizedBox(height: 6),
              Text(
                item.value,
                style: textTheme.titleLarge?.copyWith(
                  color: context.themeTextMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.helper != null) ...[
                const SizedBox(height: 4),
                Text(item.helper!, style: helperStyle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
