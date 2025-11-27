class FinanceForecastTimelineEntry {
  final DateTime date;
  final double receivables;
  final double payables;
  final double projectedOrders;
  final double projectedPurchases;
  final double net;

  const FinanceForecastTimelineEntry({
    required this.date,
    required this.receivables,
    required this.payables,
    required this.projectedOrders,
    required this.projectedPurchases,
    required this.net,
  });

  factory FinanceForecastTimelineEntry.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) {
        if (value > 1e12) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return FinanceForecastTimelineEntry(
      date: parseDate(map['date']),
      receivables: parseDouble(map['receivables']),
      payables: parseDouble(map['payables']),
      projectedOrders: parseDouble(map['projectedOrders']),
      projectedPurchases: parseDouble(map['projectedPurchases']),
      net: parseDouble(map['net']),
    );
  }
}

class FinanceForecastModel {
  final int days;
  final List<FinanceForecastTimelineEntry> timeline;

  const FinanceForecastModel({
    required this.days,
    required this.timeline,
  });

  factory FinanceForecastModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const FinanceForecastModel(days: 0, timeline: []);
    }

    final timelineEntries = <FinanceForecastTimelineEntry>[];
    final timelineData = map['timeline'] ?? map['data'] ?? map['entries'];
    if (timelineData is List) {
      for (final entry in timelineData) {
        if (entry is Map) {
          timelineEntries.add(
            FinanceForecastTimelineEntry.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          );
        }
      }
    }

    return FinanceForecastModel(
      days: map['days'] is int
          ? map['days'] as int
          : int.tryParse(map['days']?.toString() ?? '') ?? 0,
      timeline: timelineEntries,
    );
  }
}

