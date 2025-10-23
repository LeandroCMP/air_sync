import 'package:get/get.dart';

import '../../domain/entities/order.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/deduct_materials_usecase.dart';
import '../../domain/usecases/finish_order_usecase.dart';
import '../../domain/usecases/get_order_detail_usecase.dart';
import '../../domain/usecases/reserve_materials_usecase.dart';
import '../../domain/usecases/start_order_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';

class OrderDetailController extends GetxController {
  OrderDetailController(
    this._getOrderDetailUseCase,
    this._createOrderUseCase,
    this._updateOrderUseCase,
    this._startOrderUseCase,
    this._finishOrderUseCase,
    this._reserveMaterialsUseCase,
    this._deductMaterialsUseCase,
  );

  final GetOrderDetailUseCase _getOrderDetailUseCase;
  final CreateOrderUseCase _createOrderUseCase;
  final UpdateOrderUseCase _updateOrderUseCase;
  final StartOrderUseCase _startOrderUseCase;
  final FinishOrderUseCase _finishOrderUseCase;
  final ReserveMaterialsUseCase _reserveMaterialsUseCase;
  final DeductMaterialsUseCase _deductMaterialsUseCase;

  final order = Rxn<ServiceOrder>();
  final isLoading = false.obs;

  Future<void> load(String id) async {
    isLoading.value = true;
    final result = await _getOrderDetailUseCase.call(id);
    isLoading.value = false;
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => order.value = data,
    );
  }

  Future<ServiceOrder?> save({String? id, required Map<String, dynamic> payload}) async {
    isLoading.value = true;
    final result = id == null ? await _createOrderUseCase.call(payload) : await _updateOrderUseCase.call(id, payload);
    isLoading.value = false;
    return result.fold(
      (failure) {
        Get.snackbar('Erro', failure.message);
        return null;
      },
      (data) {
        order.value = data;
        Get.snackbar('Sucesso', 'Ordem salva com sucesso');
        return data;
      },
    );
  }

  Future<void> start(String id) async {
    final result = await _startOrderUseCase.call(id);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) => Get.snackbar('Ordem iniciada', 'Cronômetro em andamento'),
    );
  }

  Future<void> finish(String id, Map<String, dynamic> payload) async {
    final result = await _finishOrderUseCase.call(id, payload);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) {
        order.value = data;
        Get.snackbar('Sucesso', 'Ordem finalizada');
      },
    );
  }

  Future<void> reserveMaterials(String id, List<Map<String, dynamic>> items) async {
    final result = await _reserveMaterialsUseCase.call(id, items);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) => Get.snackbar('Materiais reservados', 'As quantidades foram separadas'),
    );
  }

  Future<void> deductMaterials(String id, List<Map<String, dynamic>> items) async {
    final result = await _deductMaterialsUseCase.call(id, items);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) => Get.snackbar('Estoque atualizado', 'Materiais baixados com sucesso'),
    );
  }
}
