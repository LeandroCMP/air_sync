import 'package:intl/intl.dart';

class SubscriptionPlanModel {
  SubscriptionPlanModel({
    required this.code,
    required this.name,
    required this.interval,
    required this.amount,
    required this.currency,
    required this.active,
    this.seats,
    this.features = const [],
    this.description,
  });

  final String code;
  final String name;
  final String interval;
  final double amount;
  final String currency;
  final bool active;
  final int? seats;
  final List<String> features;
  final String? description;

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) {
    List<String> parseFeatures(dynamic source) {
      if (source is List) {
        return source.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
      }
      return const [];
    }

    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SubscriptionPlanModel(
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      interval: (map['interval'] ?? '').toString(),
      amount: parseAmount(map['amount']),
      currency: (map['currency'] ?? 'BRL').toString().toUpperCase(),
      active:
          map['active'] is bool ? map['active'] as bool : map['active'].toString() != 'false',
      seats: map['seats'] is num ? (map['seats'] as num).toInt() : int.tryParse('${map['seats']}'),
      features: parseFeatures(map['features']),
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toBody() {
    return {
      'code': code,
      'name': name,
      'interval': interval,
      'amount': amount,
      'currency': currency,
      'seats': seats,
      'features': features,
      'description': description,
      'active': active,
    }..removeWhere((key, value) => value == null);
  }

  String get formattedPrice {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: currencySymbol);
    return fmt.format(amount);
  }

  String get currencySymbol {
    switch (currency.toUpperCase()) {
      case 'USD':
        return r'US$';
      case 'EUR':
        return '€';
      default:
        return 'R\$';
    }
  }
}

class SubscriptionCurrentModel {
  SubscriptionCurrentModel({
    required this.status,
    this.plan,
    this.startedAt,
    this.renewsAt,
    this.trialEndsAt,
    this.suspensionOverrideUntil,
    this.suspensionOverrideReason,
    this.billingDay,
    this.billingContactName,
    this.billingContactEmail,
    this.billingContactPhone,
    this.preferredPaymentMethod,
    this.notes,
  });

  final String status;
  final SubscriptionPlanModel? plan;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final DateTime? trialEndsAt;
  final DateTime? suspensionOverrideUntil;
  final String? suspensionOverrideReason;
   final int? billingDay;
   final String? billingContactName;
   final String? billingContactEmail;
   final String? billingContactPhone;
   final String? preferredPaymentMethod;
   final String? notes;

  factory SubscriptionCurrentModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final planData = map['plan'];
    return SubscriptionCurrentModel(
      status: (map['status'] ?? '').toString(),
      plan: planData is Map<String, dynamic> ? SubscriptionPlanModel.fromMap(planData) : null,
      startedAt: parseDate(map['startedAt'] ?? map['createdAt']),
      renewsAt: parseDate(map['renewsAt'] ?? map['renews_at'] ?? map['nextCycleAt']),
      trialEndsAt: parseDate(map['trialEndsAt'] ?? map['trial_ends_at']),
      suspensionOverrideUntil: parseDate(map['suspensionOverrideUntil']),
      suspensionOverrideReason: map['suspensionOverrideReason']?.toString(),
      billingDay: map['billingDay'] is num
          ? (map['billingDay'] as num).toInt()
          : int.tryParse('${map['billingDay'] ?? ''}'),
      billingContactName: map['billingContactName']?.toString(),
      billingContactEmail: map['billingContactEmail']?.toString(),
      billingContactPhone: map['billingContactPhone']?.toString(),
      preferredPaymentMethod: map['preferredPaymentMethod']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

class SubscriptionOverviewModel {
  const SubscriptionOverviewModel({
    required this.mrr,
    required this.arr,
    required this.last30Revenue,
    required this.outstandingAmount,
    this.currency = 'BRL',
    this.nextInvoice,
  });

  final double mrr;
  final double arr;
  final double last30Revenue;
  final double outstandingAmount;
  final String currency;
  final SubscriptionInvoiceModel? nextInvoice;

  factory SubscriptionOverviewModel.fromMap(Map<String, dynamic> map) {
    double parse(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    final nextInvoiceData = map['nextInvoice'];
    return SubscriptionOverviewModel(
      mrr: parse(map['mrr']),
      arr: parse(map['arr']),
      last30Revenue: parse(map['last30DaysRevenue'] ?? map['last30Revenue']),
      outstandingAmount: parse(map['outstandingAmount']),
      currency: (map['currency'] ?? 'BRL').toString().toUpperCase(),
      nextInvoice: nextInvoiceData is Map<String, dynamic>
          ? SubscriptionInvoiceModel.fromMap(nextInvoiceData)
          : null,
    );
  }
}

class SubscriptionAlertModel {
  SubscriptionAlertModel({
    required this.status,
    this.message,
    this.trialEndsAt,
    this.nextDueDate,
    this.daysUntilDue,
    this.suspensionOverrideUntil,
    this.suspensionOverrideReason,
  });

  final String status;
  final String? message;
  final DateTime? trialEndsAt;
  final DateTime? nextDueDate;
  final int? daysUntilDue;
  final DateTime? suspensionOverrideUntil;
  final String? suspensionOverrideReason;

  factory SubscriptionAlertModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return SubscriptionAlertModel(
      status: (map['status'] ?? '').toString(),
      message: map['message']?.toString(),
      trialEndsAt: parseDate(map['trialEndsAt']),
      nextDueDate: parseDate(map['nextDueDate']),
      daysUntilDue: parseInt(map['daysUntilDue']),
      suspensionOverrideUntil: parseDate(map['suspensionOverrideUntil']),
      suspensionOverrideReason: map['suspensionOverrideReason']?.toString(),
    );
  }
}

class SubscriptionInvoiceModel {
  SubscriptionInvoiceModel({
    required this.id,
    required this.status,
    required this.amountDue,
    required this.currency,
    this.dueDate,
    this.createdAt,
    this.pdfUrl,
    this.reference,
    this.paymentMethod,
    this.stripeInvoiceId,
  });

  final String id;
  final String status;
  final double amountDue;
  final String currency;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String? pdfUrl;
  final String? reference;
  final String? paymentMethod;
  final String? stripeInvoiceId;

  factory SubscriptionInvoiceModel.fromMap(Map<String, dynamic> map) {
    double parseAmount(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return SubscriptionInvoiceModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      amountDue: parseAmount(map['amount'] ?? map['amountDue'] ?? map['total']),
      currency: (map['currency'] ?? 'BRL').toString().toUpperCase(),
      dueDate: parseDate(map['dueDate']),
      createdAt: parseDate(map['createdAt']),
      pdfUrl: map['pdfUrl']?.toString(),
      reference: map['reference']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      stripeInvoiceId: map['stripeInvoiceId']?.toString(),
    );
  }

  bool get isPending => status == 'pending' || status == 'past_due';
}

class SubscriptionPaymentIntentResult {
  SubscriptionPaymentIntentResult({
    required this.clientSecret,
    required this.method,
    this.pixQrCodeBase64,
    this.pixCopyAndPaste,
    this.expiresAt,
    this.paymentIntentId,
    this.publishableKey,
    this.raw,
  });

  final String clientSecret;
  final String method;
  final String? pixQrCodeBase64;
  final String? pixCopyAndPaste;
  final DateTime? expiresAt;
  final String? paymentIntentId;
  final String? publishableKey;
  final Map<String, dynamic>? raw;

  factory SubscriptionPaymentIntentResult.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return SubscriptionPaymentIntentResult(
      clientSecret: (map['clientSecret'] ?? '').toString(),
      method: (map['method'] ?? map['paymentMethod'] ?? '').toString(),
      pixQrCodeBase64: map['pixQrCode']?.toString() ?? map['qrCode']?.toString(),
      pixCopyAndPaste:
          map['pixCopyAndPaste']?.toString() ?? map['copyAndPaste']?.toString(),
      expiresAt: parseDate(map['expiresAt']),
      paymentIntentId: map['paymentIntentId']?.toString() ?? map['id']?.toString(),
      publishableKey: map['publishableKey']?.toString() ??
          map['publicKey']?.toString() ??
          map['stripePublicKey']?.toString(),
      raw: map,
    );
  }
}
