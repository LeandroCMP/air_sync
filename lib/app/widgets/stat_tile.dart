import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.title, required this.value, this.trend});

  final String title;
  final String value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (trend != null) ...[
              const SizedBox(height: 4),
              Text(trend!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
            ],
          ],
        ),
      ),
    );
  }
}
