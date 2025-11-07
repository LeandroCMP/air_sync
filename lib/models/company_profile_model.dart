class CompanyCreditFee {
  CompanyCreditFee({required this.installments, required this.feePercent});

  final int installments;
  final double feePercent;

  factory CompanyCreditFee.fromMap(Map<String, dynamic> map) {
    final installments = map['installments'];
    final feePercent = map['feePercent'];
    return CompanyCreditFee(
      installments: installments is num ? installments.toInt() : 0,
      feePercent: feePercent is num ? feePercent.toDouble() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'installments': installments,
        'feePercent': feePercent,
      };
}

class CompanyProfileModel {
  CompanyProfileModel({
    required this.id,
    required this.name,
    required this.pixKey,
    required this.creditFees,
    required this.debitFeePercent,
    required this.chequeFeePercent,
  });

  final String id;
  final String name;
  final String pixKey;
  final List<CompanyCreditFee> creditFees;
  final double debitFeePercent;
  final double chequeFeePercent;

  factory CompanyProfileModel.fromMap(Map<String, dynamic> map) {
    final fees =
        (map['creditFees'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => CompanyCreditFee.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => a.installments.compareTo(b.installments));
    return CompanyProfileModel(
      id: map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      pixKey: map['pixKey']?.toString() ?? '',
      creditFees: fees,
      debitFeePercent:
          map['debitFeePercent'] is num ? (map['debitFeePercent'] as num).toDouble() : 0,
      chequeFeePercent:
          map['chequeFeePercent'] is num ? (map['chequeFeePercent'] as num).toDouble() : 0,
    );
  }

  CompanyProfileModel copyWith({
    String? name,
    String? pixKey,
    List<CompanyCreditFee>? creditFees,
    double? debitFeePercent,
    double? chequeFeePercent,
  }) {
    return CompanyProfileModel(
      id: id,
      name: name ?? this.name,
      pixKey: pixKey ?? this.pixKey,
      creditFees: creditFees ?? this.creditFees,
      debitFeePercent: debitFeePercent ?? this.debitFeePercent,
      chequeFeePercent: chequeFeePercent ?? this.chequeFeePercent,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'pixKey': pixKey,
        'creditFees': creditFees.map((fee) => fee.toMap()).toList(),
        'debitFeePercent': debitFeePercent,
        'chequeFeePercent': chequeFeePercent,
      };
}

class CompanyProfileExport {
  CompanyProfileExport({required this.exportedAt, required this.profile});

  final DateTime exportedAt;
  final CompanyProfileModel profile;

  factory CompanyProfileExport.fromMap(Map<String, dynamic> map) {
    return CompanyProfileExport(
      exportedAt: DateTime.tryParse(map['exportedAt']?.toString() ?? '') ?? DateTime.now(),
      profile: CompanyProfileModel.fromMap(
        Map<String, dynamic>.from(map['profile'] as Map),
      ),
    );
  }
}
