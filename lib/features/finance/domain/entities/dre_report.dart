class DreReport {
  DreReport({required this.revenue, required this.costs, required this.expenses});

  final double revenue;
  final double costs;
  final double expenses;

  double get profit => revenue - costs - expenses;
}
