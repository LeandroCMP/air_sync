import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl();

  final ApiClient _api = Get.find<ApiClient>();
  static const _endpoint = '/v1/clients';

  List<ClientModel> _mapClientList(dynamic source) {
    Iterable<dynamic>? raw;

    dynamic unwrap(dynamic value) {
      if (value is Map<String, dynamic>) {
        if (value['data'] != null) return unwrap(value['data']);
        if (value['items'] != null) return unwrap(value['items']);
        if (value['results'] != null) return unwrap(value['results']);
        if (value['clients'] != null) return unwrap(value['clients']);
        if (value['rows'] != null) return unwrap(value['rows']);
        if (value['content'] != null) return unwrap(value['content']);
      }
      return value;
    }

    final unwrapped = unwrap(source);
    if (unwrapped is List) {
      raw = unwrapped;
    } else if (unwrapped is Map<String, dynamic>) {
      final candidate = unwrapped.values.firstWhere(
        (value) => value is List,
        orElse: () => null,
      );
      if (candidate is Iterable) {
        raw = candidate.cast();
      } else {
        raw = [unwrapped];
      }
    } else if (unwrapped != null) {
      raw = [unwrapped];
    }

    if (raw == null) return const [];

    final clients = <ClientModel>[];
    for (final entry in raw) {
      try {
        if (entry is Map) {
          final map = <String, dynamic>{};
          entry.forEach((key, value) {
            map[key.toString()] = value;
          });
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          if (id.isEmpty) continue;
          clients.add(ClientModel.fromMap(id, map));
        }
      } catch (_) {
        // ignora item inválido
      }
    }
    return clients;
  }

  ClientModel _mapSingle(dynamic source) {
    if (source is Map<String, dynamic>) {
      final data = source['data'];
      if (data is Map<String, dynamic>) {
        return ClientModel.fromResponse({...source, 'data': data});
      }
      final id = (source['id'] ?? source['_id'] ?? '').toString();
      if (id.isNotEmpty) {
        return ClientModel.fromMap(id, Map<String, dynamic>.from(source));
      }
    }
    if (source is List && source.isNotEmpty) {
      return _mapSingle(source.first);
    }
    throw ClientFailure.unknown('Resposta de cliente inválida');
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;

    String? pick(dynamic value) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List) {
        for (final entry in value) {
          final text = pick(entry);
          if (text != null && text.isNotEmpty) return text;
        }
      } else if (value is Map) {
        final detail = pick(value['detail'] ?? value['message']);
        if (detail != null) {
          final field =
              (value['field'] ?? value['property'] ?? value['path'])
                  ?.toString();
          if (field != null && field.isNotEmpty) {
            return '$field: $detail';
          }
          return detail;
        }
        final constraints = value['constraints'];
        if (constraints is Map) {
          final buffer = <String>[];
          for (final entry in constraints.values) {
            final text = pick(entry);
            if (text != null && text.isNotEmpty) buffer.add(text);
          }
          if (buffer.isNotEmpty) return buffer.join(' | ');
        }
        final nested = pick(value['errors'] ?? value['details']);
        if (nested != null) return nested;
      }
      return null;
    }

    final message =
        pick(data) ??
        pick(error.message) ??
        pick(error.response?.statusMessage) ??
        fallback;

    return message;
  }

  Never _handleDio(DioException error, {required String fallback}) {
    final status = error.response?.statusCode ?? 500;
    final message = _extractErrorMessage(error, fallback);

    if (status == 400 || status == 422) {
      throw ClientFailure.validation(message);
    }
    if (status == 404) {
      throw ClientFailure.validation(
        message.isEmpty ? 'Cliente não encontrado' : message,
      );
    }
    throw ClientFailure.firebase(message);
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};
    payload.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      sanitized[key] = value;
    });
    return sanitized;
  }

  @override
  Future<List<ClientModel>> list({
    String? text,
    int page = 1,
    int limit = 20,
    bool includeDeleted = false,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if ((text ?? '').trim().isNotEmpty) 'text': text!.trim(),
      if (includeDeleted) 'includeDeleted': 'true',
    };

    try {
      final res = await _api.dio.get(_endpoint, queryParameters: query);
      return _mapClientList(res.data);
    } on DioException catch (e) {
      _handleDio(e, fallback: 'Erro ao listar clientes');
    }
  }

  @override
  Future<ClientModel> getById(String id) async {
    try {
      final res = await _api.dio.get('$_endpoint/$id');
      return _mapSingle(res.data);
    } on DioException catch (e) {
      _handleDio(e, fallback: 'Erro ao buscar cliente');
    }
  }

  @override
  Future<ClientModel> create(ClientModel client) async {
    if (client.name.trim().isEmpty) {
      throw ClientFailure.validation('Nome do cliente é obrigatório');
    }

    final payload = _sanitizePayload(client.toCreatePayload());

    try {
      final res = await _api.dio.post(_endpoint, data: payload);
      return _mapSingle(res.data);
    } on DioException catch (e) {
      _handleDio(e, fallback: 'Erro ao criar cliente');
    }
  }

  @override
  Future<ClientModel> update(
    ClientModel client, {
    ClientModel? original,
  }) async {
    if (client.id.isEmpty) {
      throw ClientFailure.validation(
        'ID do cliente é obrigatório para atualização',
      );
    }

    final payload = _sanitizePayload(
      client.toUpdatePayload(original: original),
    );

    if (payload.isEmpty) {
      return client;
    }

    try {
      final res = await _api.dio.patch(
        '$_endpoint/${client.id}',
        data: payload,
      );
      return _mapSingle(res.data);
    } on DioException catch (e) {
      _handleDio(e, fallback: 'Erro ao atualizar cliente');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete('$_endpoint/$id');
    } on DioException catch (e) {
      _handleDio(e, fallback: 'Erro ao remover cliente');
    }
  }
}
