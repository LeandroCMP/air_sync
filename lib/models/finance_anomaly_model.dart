class FinanceAnomalyInsight {
  const FinanceAnomalyInsight({
    required this.title,
    required this.description,
    this.severity,
    this.category,
    this.impactValue,
    this.recommendation,
  });

  final String title;
  final String description;
  final String? severity;
  final String? category;
  final double? impactValue;
  final String? recommendation;

  factory FinanceAnomalyInsight.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return FinanceAnomalyInsight(
      title: (map['title'] ?? map['name'] ?? 'Anomalia').toString(),
      description:
          (map['description'] ?? map['message'] ?? map['details'] ?? '')
              .toString(),
      severity: (map['severity'] ?? map['level'])?.toString(),
      category: (map['category'] ?? map['type'])?.toString(),
      impactValue: parseDouble(map['impact'] ?? map['value']),
      recommendation:
          (map['recommendation'] ?? map['suggestion'] ?? map['action'])
              ?.toString(),
    );
  }
}

class FinanceAnomalyReport {
  const FinanceAnomalyReport({
    this.summary,
    this.generatedAt,
    required this.items,
  });

  final String? summary;
  final DateTime? generatedAt;
  final List<FinanceAnomalyInsight> items;

  factory FinanceAnomalyReport.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final list = ((map['items'] ?? map['anomalies']) as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => FinanceAnomalyInsight.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();

    String? resolveSummary() {
      final summary = map['summary'] ?? map['overview'] ?? map['text'];
      if (summary == null) return null;
      final text = summary.toString().trim();
      return text.isEmpty ? null : text;
    }

    return FinanceAnomalyReport(
      summary: resolveSummary(),
      generatedAt: parseDate(map['generatedAt'] ?? map['date']),
      items: list,
    );
  }

  factory FinanceAnomalyReport.fromResponse(dynamic data) {
    if (data is Map) {
      return FinanceAnomalyReport.fromMap(Map<String, dynamic>.from(data));
    }
    if (data is List) {
      final list = data
          .whereType<Map>()
          .map(
            (entry) => FinanceAnomalyInsight.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
      return FinanceAnomalyReport(summary: null, generatedAt: null, items: list);
    }
    if (data is String) {
      return FinanceAnomalyReport(
        summary: data.trim().isEmpty ? null : data.trim(),
        generatedAt: null,
        items: const [],
      );
    }
    return const FinanceAnomalyReport(summary: null, generatedAt: null, items: []);
  }

  bool get hasItems => items.isNotEmpty;
}
