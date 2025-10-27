import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/services/orders/orders_service.dart';

class OrdersServiceImpl implements OrdersService {
  final OrdersRepository _repo;
  OrdersServiceImpl({required OrdersRepository repo}) : _repo = repo;

  @override
  Future<List<OrderModel>> list({DateTime? from, DateTime? to, String? status}) =>
      _repo.list(from: from, to: to, status: status);

  @override
  Future<void> finish({required String orderId, required Map<String, dynamic> payload}) =>
      _repo.finish(orderId: orderId, payload: payload);

  @override
  Future<void> start(String orderId) => _repo.start(orderId);

  @override
  Future<void> reserveMaterials(String orderId, List<Map<String, dynamic>> items) =>
      _repo.reserveMaterials(orderId, items);

  @override
  String pdfUrl(String orderId, {String type = 'report'}) => _repo.pdfUrl(orderId, type: type);

  
}
