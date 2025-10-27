import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _api = Get.find<ApiClient>();

  String get _basePath => '/v1/inventory/items';

  @override
  Future<List<InventoryItemModel>> getItems(String userId) async {
    try {
      final res = await _api.dio.get(_basePath);
      final data = res.data;
      if (data is List) {
        return data
            .cast<Map<String, dynamic>>()
            .map((e) => InventoryItemModel.fromMap(
                  (e['id'] ?? e['_id'] ?? '').toString(),
                  e,
                ))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao buscar itens: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao buscar itens do estoque');
    }
  }

  @override
  Future<InventoryItemModel> registerItem(InventoryItemModel item) async {
    try {
      if (item.description.isEmpty || item.unit.isEmpty || item.quantity <= 0) {
        throw InventoryFailure.validation(
          'Descrição, unidade e quantidade são obrigatórios',
        );
      }

      final payload = {
        'description': item.description,
        'unit': item.unit,
        'quantity': item.quantity,
      };

      final res = await _api.dio.post(_basePath, data: payload);
      final data = res.data as Map<String, dynamic>;
      final id = (data['id'] ?? data['_id'] ?? '').toString();
      return item.copyWith(id: id);
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao registrar item: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao cadastrar item');
    }
  }

  @override
  Future<void> updateItem(InventoryItemModel item) async {
    try {
      if (item.id.isEmpty) {
        throw InventoryFailure.validation('ID do item é obrigatório para atualização');
      }
      final payload = {
        'description': item.description,
        'unit': item.unit,
        'quantity': item.quantity,
      };
      await _api.dio.patch('$_basePath/${item.id}', data: payload);
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao atualizar item: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao atualizar item');
    }
  }

  @override
  Future<void> addRecord({required String itemId, required double quantityToAdd}) async {
    try {
      // Atualiza quantidade agregada; histórico depende da API
      await _api.dio.post('$_basePath/$itemId/increment', data: {
        'qty': quantityToAdd,
      });
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao adicionar registro: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao registrar entrada');
    }
  }

  @override
  Future<void> deleteEntry({required String itemId, required String entryId}) async {
    try {
      await _api.dio.delete('$_basePath/$itemId/entries/$entryId');
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao deletar entrada: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao deletar entrada');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      if (itemId.isEmpty) {
        throw InventoryFailure.validation('ID do item é obrigatório para exclusão');
      }
      await _api.dio.delete('$_basePath/$itemId');
    } on DioException catch (e) {
      throw InventoryFailure.firebase('Erro ao deletar item: ${e.message}');
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao deletar item');
    }
  }
}

