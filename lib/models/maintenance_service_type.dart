class MaintenanceServiceType {
  MaintenanceServiceType({
    required this.code,
    required this.name,
    required this.defaultIntervalDays,
  });

  final String code;
  final String name;
  final int defaultIntervalDays;

  factory MaintenanceServiceType.fromMap(Map<String, dynamic> map) {
    final code = (map['code'] ?? map['id'] ?? '').toString();
    final name = (map['name'] ?? '').toString();
    final interval = map['defaultIntervalDays'];
    final days =
        interval is num ? interval.toInt() : int.tryParse('$interval') ?? 0;

    return MaintenanceServiceType(
      code: code,
      name: name,
      defaultIntervalDays: days,
    );
  }

  String get labelWithInterval =>
      defaultIntervalDays > 0 ? '$name \u2013 $defaultIntervalDays dias' : name;
}
