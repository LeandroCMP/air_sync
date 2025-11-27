import 'dart:math' as math;

import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/finance/widgets/finance_dashboard_card.dart';
import 'package:flutter/material.dart';

class PaymentMethodChartData {
  final String label;
  final double gross;
  final double fees;
  final double net;

  const PaymentMethodChartData({
    required this.label,
    required this.gross,
    required this.fees,
    required this.net,
  });

  double get displayValue {
    if (gross.abs() > 0) return gross.abs();
    if (net.abs() > 0) return net.abs();
    if (fees.abs() > 0) return fees.abs();
    return 0;
  }
}

class PaymentMethodChart extends StatelessWidget {
  final List<PaymentMethodChartData> data;
  final String Function(double value) currencyBuilder;

  const PaymentMethodChart({
    super.key,
    required this.data,
    required this.currencyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final totalGross = data.fold<double>(0, (sum, item) => sum + item.gross.abs());
    final totalDisplay =
        data.fold<double>(0, (sum, item) => sum + item.displayValue);
    final palette = [
      const Color(0xFF4DA3FF),
      const Color(0xFFFFA15C),
      const Color(0xFF00B686),
      const Color(0xFF9B59B6),
      const Color(0xFF46D0E6),
    ];

    final hasDisplayData = data.isNotEmpty && totalDisplay > 0;
    final segments = hasDisplayData
        ? data.asMap().entries
            .map((entry) {
              final value = entry.value.displayValue;
              if (value <= 0) return null;
              final color = palette[entry.key % palette.length];
              return _ChartSegment(value: value, color: color);
            })
            .whereType<_ChartSegment>()
            .toList()
        : <_ChartSegment>[
            _ChartSegment(
              value: 1,
              color: context.themeBorder.withValues(alpha: .6),
            ),
          ];

    final displayedTotal = totalDisplay > 0 ? totalDisplay : totalGross;
    final caption = totalGross > 0 ? 'Bruto do mês' : 'Total processado';

    return FinanceDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagamentos por método',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.themeTextMain,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVertical = constraints.maxWidth < 600;
              final chart = _DonutChart(
                segments: segments,
                label: currencyBuilder(displayedTotal),
                caption: caption,
              );
              final legend = _PaymentLegendList(
                data: data,
                palette: palette,
                currencyBuilder: currencyBuilder,
                totalValue: totalDisplay > 0 ? totalDisplay : totalGross,
              );

              if (isVertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chart,
                    const SizedBox(height: 20),
                    legend,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 180, child: chart),
                  const SizedBox(width: 24),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentLegendList extends StatelessWidget {
  final List<PaymentMethodChartData> data;
  final List<Color> palette;
  final String Function(double) currencyBuilder;
  final double totalValue;

  const _PaymentLegendList({
    required this.data,
    required this.palette,
    required this.currencyBuilder,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Sem pagamentos registrados para o período.',
        style: TextStyle(color: context.themeTextSubtle),
      );
    }

    return Column(
      children: data.asMap().entries.map((entry) {
        final color = palette[entry.key % palette.length];
        final item = entry.value;
        final double percent =
            totalValue <= 0 ? 0 : (item.displayValue / totalValue).clamp(0.0, 1.0);
        final double reference =
            item.gross.abs() > 0 ? item.gross.abs() : item.net.abs();
        final double netRatio =
            reference == 0 ? 0 : (item.net.abs() / reference).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: context.themeTextMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: context.themeTextSubtle),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Bruto ${currencyBuilder(item.gross)}',
                    style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
                  ),
                  Text(
                    'Taxas ${currencyBuilder(item.fees)}',
                    style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
                  ),
                  Text(
                    'Líquido ${currencyBuilder(item.net)}',
                    style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: netRatio,
                  backgroundColor: color.withValues(alpha: .18),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<_ChartSegment> segments;
  final String label;
  final String caption;

  const _DonutChart({
    required this.segments,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _DonutChartPainter(
              segments: segments,
              backgroundColor: context.themeBorder.withValues(alpha: .4),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.themeTextMain,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: TextStyle(
                  color: context.themeTextSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSegment {
  final double value;
  final Color color;

  _ChartSegment({required this.value, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final double strokeWidth;
  final Color backgroundColor;

  const _DonutChartPainter({
    required this.segments,
    required this.backgroundColor,
  }) : strokeWidth = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    final arcRect = rect.deflate(strokeWidth / 2);

    if (total <= 0) {
      paint.color = backgroundColor;
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, paint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * (math.pi * 2);
      paint.color = segment.color;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
