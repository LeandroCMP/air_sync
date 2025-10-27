import 'package:air_sync/models/order_model.dart';

abstract class OrdersRepository {
  Future<List<OrderModel>> list({
    DateTime? from,
    DateTime? to,
    String? status, // scheduled|in_progress|finished|canceled
  });

  Future<void> finish({
    required String orderId,
    required Map<String, dynamic> payload,
  });

  Future<void> start(String orderId);

  Future<void> reserveMaterials(String orderId, List<Map<String, dynamic>> items);

  String pdfUrl(String orderId, {String type = 'report'});
}
