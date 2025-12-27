import 'package:dio/dio.dart';

class OrderBookingConflict {
  OrderBookingConflict({
    required this.message,
    this.orderId,
    List<String>? technicianIds,
  }) : technicianIds = technicianIds ?? const [];

  final String message;
  final String? orderId;
  final List<String> technicianIds;
}

OrderBookingConflict? parseOrderBookingConflict(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;

  Map<dynamic, dynamic>? asMap(dynamic source) {
    if (source is Map) return source;
    return null;
  }

  Map<dynamic, dynamic>? errorBody;
  if (data is Map && data['error'] is Map) {
    errorBody = asMap(data['error']);
  } else if (data is Map) {
    errorBody = data;
  }

  if (errorBody == null) return null;
  final code = errorBody['code']?.toString();
  if (code != 'TECH_ALREADY_BOOKED') return null;

  final message =
      errorBody['message']?.toString().trim().isNotEmpty == true
          ? errorBody['message'].toString().trim()
          : 'Este t\u00e9cnico j\u00e1 tem OS nesse hor\u00e1rio.';

  Map<dynamic, dynamic>? details;
  if (errorBody['details'] is Map) {
    details = Map<dynamic, dynamic>.from(errorBody['details'] as Map);
  } else if (data is Map && data['details'] is Map) {
    details = Map<dynamic, dynamic>.from(data['details'] as Map);
  }

  final technicianIds = <String>[];
  final techField = details?['technicianIds'];
  if (techField is List) {
    technicianIds.addAll(
      techField
          .map((e) => e?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty),
    );
  }

  return OrderBookingConflict(
    message: message,
    orderId: details?['orderId']?.toString(),
    technicianIds: technicianIds,
  );
}
