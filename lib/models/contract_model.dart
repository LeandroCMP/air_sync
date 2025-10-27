class ContractModel {
  final String id;
  final String clientId;
  final List<String> equipmentIds;
  final String status;
  final String planName;
  final int intervalMonths;
  final int slaHours;
  final double priceMonthly;
  final String? notes;
  ContractModel({
    required this.id,
    required this.clientId,
    required this.equipmentIds,
    required this.status,
    required this.planName,
    required this.intervalMonths,
    required this.slaHours,
    required this.priceMonthly,
    this.notes,
  });
  factory ContractModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final plan = (map['plan'] as Map?) ?? {};
    return ContractModel(
      id: id,
      clientId: (map['clientId'] ?? '').toString(),
      equipmentIds: ((map['equipmentIds'] as List?) ?? []).map((e) => e.toString()).toList(),
      status: (map['status'] ?? '').toString(),
      planName: (plan['name'] ?? '').toString(),
      intervalMonths: (plan['intervalMonths'] is num) ? (plan['intervalMonths'] as num).toInt() : 0,
      slaHours: (plan['slaHours'] is num) ? (plan['slaHours'] as num).toInt() : 0,
      priceMonthly: (map['priceMonthly'] is num) ? (map['priceMonthly'] as num).toDouble() : 0,
      notes: map['notes']?.toString(),
    );
  }
}

