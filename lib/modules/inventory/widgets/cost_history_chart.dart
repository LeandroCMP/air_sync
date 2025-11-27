import 'package:air_sync/models/inventory_model.dart';
import 'package:flutter/material.dart';

/// Sparkline-style chart to visualize the evolution of cost history.
class InventoryCostHistoryChart extends StatelessWidget {
  const InventoryCostHistoryChart({
    super.key,
    required this.entries,
    this.height = 160,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<InventoryCostHistoryEntry> entries;
  final double height;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _InventoryCostHistoryChartPainter(
            entries: entries,
            lineColor: lineColor,
            fillColor: fillColor,
            gridColor: gridColor,
          ),
        ),
      ),
    );
  }
}

class _InventoryCostHistoryChartPainter extends CustomPainter {
  _InventoryCostHistoryChartPainter({
    required this.entries,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<InventoryCostHistoryEntry> entries;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final sorted = List<InventoryCostHistoryEntry>.from(entries)
      ..sort((a, b) => a.at.compareTo(b.at));
    final minCost = sorted.fold<double>(
      double.infinity,
      (value, entry) => entry.cost < value ? entry.cost : value,
    );
    final maxCost = sorted.fold<double>(
      -double.infinity,
      (value, entry) => entry.cost > value ? entry.cost : value,
    );
    final minTime = sorted.first.at.millisecondsSinceEpoch.toDouble();
    final maxTime = sorted.last.at.millisecondsSinceEpoch.toDouble();
    final dx = size.width - 24;
    final dy = size.height - 24;
    const offsetX = 12.0;
    const offsetY = 12.0;
    final costRange = (maxCost - minCost).abs() < 0.001
        ? 1.0
        : (maxCost - minCost);
    final timeRange = (maxTime - minTime).abs() < 0.001
        ? 1.0
        : (maxTime - minTime);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = offsetY + (dy * (i / 3));
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + dx, y),
        gridPaint,
      );
    }

    final points = sorted.map((entry) {
      final normalizedTime =
          (entry.at.millisecondsSinceEpoch - minTime) / timeRange;
      final normalizedCost = (entry.cost - minCost) / costRange;
      final x = offsetX + (normalizedTime * dx);
      final y = offsetY + dy - (normalizedCost * dy);
      return Offset(x, y);
    }).toList();

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(points.last.dx, offsetY + dy)
      ..lineTo(points.first.dx, offsetY + dy)
      ..close();
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = lineColor;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
