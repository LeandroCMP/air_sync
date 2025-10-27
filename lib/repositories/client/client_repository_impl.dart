import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<ClientModel>> getClientsByUserId(String userId) async {
    try {
      final res = await _api.dio.get('/v1/clients');
      final data = res.data;
      if (data is List) {
        return data
            .cast<Map<String, dynamic>>()
            .map((e) {
              final id = (e['id'] ?? e['_id'] ?? '').toString();
              return ClientModel.fromMap(id, e);
            })
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ClientFailure.firebase('Erro ao buscar clientes: ${e.message}');
    } catch (_) {
      throw ClientFailure.unknown('Erro inesperado ao buscar clientes');
    }
  }

  @override
  Future<ClientModel> registerClient(ClientModel client) async {
    try {
      if (client.name.isEmpty || client.primaryPhone.isEmpty) {
        throw ClientFailure.validation('Nome e telefone são obrigatórios');
      }

      final payload = client.toCreatePayload();

      final res = await _api.dio.post('/v1/clients', data: payload);
      final data = res.data as Map<String, dynamic>;
      final id = (data['id'] ?? data['_id'] ?? '').toString();
      return client.copyWith(id: id);
    } on DioException catch (e) {
      throw ClientFailure.firebase('Erro ao registrar cliente: ${e.message}');
    } catch (_) {
      throw ClientFailure.unknown('Erro inesperado ao cadastrar cliente');
    }
  }

  @override
  Future<void> updateClient(ClientModel client) async {
    try {
      if (client.id.isEmpty) {
        throw ClientFailure.validation('ID do cliente é obrigatório para atualização');
      }
      final payload = client.toUpdatePayload();
      await _api.dio.patch('/v1/clients/${client.id}', data: payload);
    } on DioException catch (e) {
      throw ClientFailure.firebase('Erro ao atualizar cliente: ${e.message}');
    } catch (_) {
      throw ClientFailure.unknown('Erro inesperado ao atualizar cliente');
    }
  }
}



