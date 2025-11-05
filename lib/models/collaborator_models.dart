enum CollaboratorRole { admin, manager, tech, viewer }

CollaboratorRole collaboratorRoleFromString(String value) =>
    CollaboratorRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => CollaboratorRole.viewer,
    );

enum PaymentFrequency { monthly, biweekly, weekly }

PaymentFrequency? paymentFrequencyFromString(String? value) {
  if (value == null) return null;
  switch (value) {
    case 'monthly':
      return PaymentFrequency.monthly;
    case 'biweekly':
      return PaymentFrequency.biweekly;
    case 'weekly':
      return PaymentFrequency.weekly;
  }
  return null;
}

enum PaymentMethod { pix, cash, card, bankTransfer }

PaymentMethod? paymentMethodFromString(String? value) {
  if (value == null) return null;
  switch (value) {
    case 'PIX':
      return PaymentMethod.pix;
    case 'CASH':
      return PaymentMethod.cash;
    case 'CARD':
      return PaymentMethod.card;
    case 'BANK_TRANSFER':
      return PaymentMethod.bankTransfer;
  }
  return null;
}

String paymentMethodToApi(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.pix:
      return 'PIX';
    case PaymentMethod.cash:
      return 'CASH';
    case PaymentMethod.card:
      return 'CARD';
    case PaymentMethod.bankTransfer:
      return 'BANK_TRANSFER';
  }
}

class CollaboratorCompensation {
  CollaboratorCompensation({
    this.salary,
    this.paymentDay,
    this.paymentFrequency,
    this.paymentMethod,
    this.notes,
  });

  final double? salary;
  final int? paymentDay;
  final PaymentFrequency? paymentFrequency;
  final PaymentMethod? paymentMethod;
  final String? notes;

  factory CollaboratorCompensation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CollaboratorCompensation();
    return CollaboratorCompensation(
      salary: (map['salary'] as num?)?.toDouble(),
      paymentDay: map['paymentDay'] as int?,
      paymentFrequency: paymentFrequencyFromString(
        map['paymentFrequency'] as String?,
      ),
      paymentMethod: paymentMethodFromString(map['paymentMethod'] as String?),
      notes: (map['notes'] as String?)?.trim(),
    );
  }
}

class CollaboratorModel {
  CollaboratorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    required this.active,
    this.tenantId,
    this.hourlyCost,
    this.compensation,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? tenantId;
  final String name;
  final String email;
  final CollaboratorRole role;
  final List<String> permissions;
  final double? hourlyCost;
  final CollaboratorCompensation? compensation;
  final bool active;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory CollaboratorModel.fromMap(Map<String, dynamic> map) {
    final compensation = CollaboratorCompensation.fromMap(
      map['compensation'] as Map<String, dynamic>?,
    );
    return CollaboratorModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      tenantId: map['tenantId']?.toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: collaboratorRoleFromString((map['role'] ?? 'viewer').toString()),
      permissions:
          ((map['permissions'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      hourlyCost: (map['hourlyCost'] as num?)?.toDouble(),
      compensation: compensation,
      active:
          map['active'] == null
              ? true
              : (map['active'] is bool
                  ? map['active'] as bool
                  : map['active'].toString() != 'false'),
      updatedBy: map['updatedBy']?.toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()),
      deletedAt: DateTime.tryParse((map['deletedAt'] ?? '').toString()),
    );
  }
}

class PermissionCatalogEntry {
  PermissionCatalogEntry({
    required this.code,
    required this.label,
    this.description,
    this.module,
  });

  final String code;
  final String label;
  final String? description;
  final String? module;

  factory PermissionCatalogEntry.fromMap(Map<String, dynamic> map) {
    return PermissionCatalogEntry(
      code: map['code']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      description: map['description']?.toString(),
      module: map['module']?.toString(),
    );
  }
}

class RolePresetModel {
  RolePresetModel({required this.role, required this.permissions});

  final CollaboratorRole role;
  final List<String> permissions;

  factory RolePresetModel.fromMap(Map<String, dynamic> map) {
    return RolePresetModel(
      role: collaboratorRoleFromString((map['role'] ?? 'viewer').toString()),
      permissions:
          ((map['permissions'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }
}

enum PayrollStatus { pending, paid }

PayrollStatus payrollStatusFromString(String value) =>
    PayrollStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PayrollStatus.pending,
    );

class PayrollModel {
  PayrollModel({
    required this.id,
    required this.userId,
    required this.reference,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    this.attachmentUrl,
    this.financeTransactionId,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String reference;
  final double amount;
  final PayrollStatus status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final String? attachmentUrl;
  final String? financeTransactionId;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PayrollModel.fromMap(Map<String, dynamic> map) {
    return PayrollModel(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      reference: (map['reference'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: payrollStatusFromString((map['status'] ?? 'pending').toString()),
      dueDate: DateTime.tryParse((map['dueDate'] ?? '').toString()),
      paidAt: DateTime.tryParse((map['paidAt'] ?? '').toString()),
      paymentMethod: paymentMethodFromString(map['paymentMethod'] as String?),
      notes: (map['notes'] as String?)?.trim(),
      attachmentUrl: map['attachmentUrl']?.toString(),
      financeTransactionId: map['financeTransactionId']?.toString(),
      createdBy: map['createdBy']?.toString(),
      updatedBy: map['updatedBy']?.toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()),
    );
  }
}

class CollaboratorCreateInput {
  CollaboratorCreateInput({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.permissions,
    this.salary,
    this.paymentDay,
    this.paymentFrequency,
    this.paymentMethod,
    this.hourlyCost,
    this.active,
    this.compensationNotes,
  });

  final String name;
  final String email;
  final String password;
  final CollaboratorRole role;
  final List<String>? permissions;
  final double? salary;
  final int? paymentDay;
  final PaymentFrequency? paymentFrequency;
  final PaymentMethod? paymentMethod;
  final double? hourlyCost;
  final bool? active;
  final String? compensationNotes;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
      if (permissions != null) 'permissions': permissions,
      if (salary != null) 'salary': salary,
      if (paymentDay != null) 'paymentDay': paymentDay,
      if (paymentFrequency != null) 'paymentFrequency': paymentFrequency!.name,
      if (paymentMethod != null)
        'paymentMethod': paymentMethodToApi(paymentMethod!),
      if (hourlyCost != null) 'hourlyCost': hourlyCost,
      if (active != null) 'active': active,
      if (compensationNotes != null && compensationNotes!.trim().isNotEmpty)
        'compensationNotes': compensationNotes,
    };
  }
}

class CollaboratorUpdateInput {
  CollaboratorUpdateInput({
    this.name,
    this.role,
    this.permissions,
    this.salary,
    this.paymentDay,
    this.paymentFrequency,
    this.paymentMethod,
    this.compensationNotes,
    this.hourlyCost,
    this.active,
  });

  final String? name;
  final CollaboratorRole? role;
  final List<String>? permissions;
  final double? salary;
  final int? paymentDay;
  final PaymentFrequency? paymentFrequency;
  final PaymentMethod? paymentMethod;
  final String? compensationNotes;
  final double? hourlyCost;
  final bool? active;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (role != null) data['role'] = role!.name;
    if (permissions != null) data['permissions'] = permissions;
    if (salary != null) data['salary'] = salary;
    if (paymentDay != null) data['paymentDay'] = paymentDay;
    if (paymentFrequency != null) {
      data['paymentFrequency'] = paymentFrequency!.name;
    }
    if (paymentMethod != null) {
      data['paymentMethod'] = paymentMethodToApi(paymentMethod!);
    }
    if (compensationNotes != null) {
      data['compensationNotes'] = compensationNotes;
    }
    if (hourlyCost != null) data['hourlyCost'] = hourlyCost;
    if (active != null) data['active'] = active;
    return data;
  }
}

class PayrollCreateInput {
  PayrollCreateInput({
    required this.reference,
    required this.amount,
    this.dueDate,
    this.status,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    this.attachmentBase64,
    this.attachmentFilename,
  });

  final String reference;
  final double amount;
  final DateTime? dueDate;
  final PayrollStatus? status;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final String? attachmentBase64;
  final String? attachmentFilename;

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'amount': amount,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (status != null) 'status': status!.name,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      if (paymentMethod != null)
        'paymentMethod': paymentMethodToApi(paymentMethod!),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      if (attachmentBase64 != null) 'attachmentBase64': attachmentBase64,
      if (attachmentFilename != null) 'attachmentFilename': attachmentFilename,
    };
  }
}

class PayrollUpdateInput {
  PayrollUpdateInput({
    this.reference,
    this.amount,
    this.dueDate,
    this.status,
    this.paymentMethod,
    this.paidAt,
    this.notes,
    this.attachmentBase64,
    this.attachmentFilename,
  });

  final String? reference;
  final double? amount;
  final DateTime? dueDate;
  final PayrollStatus? status;
  final PaymentMethod? paymentMethod;
  final DateTime? paidAt;
  final String? notes;
  final String? attachmentBase64;
  final String? attachmentFilename;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (reference != null) data['reference'] = reference;
    if (amount != null) data['amount'] = amount;
    if (dueDate != null) data['dueDate'] = dueDate!.toIso8601String();
    if (status != null) data['status'] = status!.name;
    if (paymentMethod != null) {
      data['paymentMethod'] = paymentMethodToApi(paymentMethod!);
    }
    if (paidAt != null) data['paidAt'] = paidAt!.toIso8601String();
    if (notes != null) data['notes'] = notes;
    if (attachmentBase64 != null) {
      data['attachmentBase64'] = attachmentBase64;
    }
    if (attachmentFilename != null) {
      data['attachmentFilename'] = attachmentFilename;
    }
    return data;
  }
}
