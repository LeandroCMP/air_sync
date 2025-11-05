class EquipmentModel {
  final String id;
  final String clientId;
  final String locationId;
  final String? brand;
  final String? model;
  final String? type;
  final int? btus;
  final String? room;
  final DateTime? installDate;
  final String? serial;
  final String? notes;

  EquipmentModel({
    required this.id,
    required this.clientId,
    required this.locationId,
    this.brand,
    this.model,
    this.type,
    this.btus,
    this.room,
    this.installDate,
    this.serial,
    this.notes,
  });

  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    return EquipmentModel(
      id: id,
      clientId: (map['clientId'] ?? '').toString(),
      locationId: (map['locationId'] ?? '').toString(),
      brand: map['brand']?.toString(),
      model: map['model']?.toString(),
      type: map['type']?.toString(),
      btus: map['btus'] is num ? (map['btus'] as num).toInt() : int.tryParse(map['btus']?.toString() ?? ''),
      room: map['room']?.toString(),
      installDate: map['installDate'] != null ? DateTime.tryParse(map['installDate'].toString()) : null,
      serial: map['serial']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

