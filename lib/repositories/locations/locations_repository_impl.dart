import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'locations_repository.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl();

  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<LocationModel> create({
    required String clientId,
    required String label,
    Map<String, String?> address = const {},
    String? notes,
  }) async {
    final payload = _buildCreatePayload(
      clientId: clientId,
      label: label,
      address: address,
      notes: notes,
    );

    try {
      final res = await _api.dio.post('/v1/locations', data: payload);
      return _mapSingle(res.data);
    } on DioException catch (e) {
      _handleDioError(
        e,
        fallback: 'Não foi possível cadastrar o endereço.',
        notFoundMessage: 'Cliente não encontrado.',
      );
    } catch (_) {
      throw ClientFailure.unknown('Não foi possível cadastrar o endereço.');
    }
  }

  @override
  Future<List<LocationModel>> listByClient(String clientId) async {
    final res = await _api.dio.get(
      '/v1/locations',
      queryParameters: {'clientId': clientId},
    );

    final data = res.data;

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (e) => LocationModel.fromMap(
              Map<String, dynamic>.from(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            ),
          )
          .toList();
    }

    if (data is Map) {
      return [
        LocationModel.fromMap(
          Map<String, dynamic>.from(
            data.map((key, value) => MapEntry(key.toString(), value)),
          ),
        ),
      ];
    }

    return const [];
  }

  @override
  Future<LocationModel> update({
    required String id,
    String? label,
    Map<String, String?> address = const {},
    String? notes,
    bool includeNotes = false,
  }) async {
    final payload = _buildUpdatePayload(
      label: label,
      address: address,
      notes: notes,
      includeNotes: includeNotes,
    );

    if (payload.isEmpty) {
      return LocationModel.fromMap({'id': id});
    }

    try {
      final res = await _api.dio.patch('/v1/locations/$id', data: payload);
      return _mapSingle(res.data);
    } on DioException catch (e) {
      _handleDioError(
        e,
        fallback: 'Não foi possível atualizar o endereço.',
        notFoundMessage: 'Endereço não encontrado.',
      );
    } catch (_) {
      throw ClientFailure.unknown('Não foi possível atualizar o endereço.');
    }
  }

  @override
  Future<void> delete(String id, {bool cascadeEquipments = false}) async {
    try {
      await _api.dio.delete(
        '/v1/locations/$id',
        queryParameters: cascadeEquipments ? {'cascadeEquipments': 'true'} : null,
      );
    } on DioException catch (e) {
      _handleDioError(
        e,
        fallback: 'Não foi possível remover o endereço.',
        notFoundMessage: 'Endereço não encontrado.',
      );
    } catch (_) {
      throw ClientFailure.unknown('Não foi possível remover o endereço.');
    }
  }

  Map<String, dynamic> _buildCreatePayload({
    required String clientId,
    required String label,
    Map<String, String?> address = const {},
    String? notes,
  }) {
    final payload = <String, dynamic>{
      'clientId': clientId,
      'label': label.trim(),
    };

    final sanitizedAddress = _sanitizeAddress(address, includeNulls: false);
    if (sanitizedAddress.isNotEmpty) {
      payload['address'] = sanitizedAddress;
    }

    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      payload['notes'] = trimmedNotes;
    }

    return payload;
  }

  Map<String, dynamic> _buildUpdatePayload({
    String? label,
    Map<String, String?> address = const {},
    String? notes,
    bool includeNotes = false,
  }) {
    final payload = <String, dynamic>{};

    final trimmedLabel = label?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      payload['label'] = trimmedLabel;
    }

    final sanitizedAddress = _sanitizeAddress(address, includeNulls: true);
    if (sanitizedAddress.isNotEmpty) {
      payload['address'] = sanitizedAddress;
    }

    if (includeNotes) {
      payload['notes'] = notes;
    }

    return payload;
  }

  Map<String, dynamic> _sanitizeAddress(
    Map<String, String?> address, {
    required bool includeNulls,
  }) {
    final sanitized = <String, dynamic>{};

    String? normalize(
      String? value, {
      bool digitsOnly = false,
      bool upper = false,
    }) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      var result = trimmed;
      if (digitsOnly) {
        result = trimmed.replaceAll(RegExp(r'\\D'), '');
      }
      if (upper) {
        result = result.toUpperCase();
      }
      return result.isEmpty ? null : result;
    }

    void addField(String key, String? value) {
      switch (key) {
        case 'zip':
          final normalized = normalize(value, digitsOnly: true);
          if (normalized != null) {
            sanitized[key] = normalized;
          } else if (includeNulls && address.containsKey(key)) {
            sanitized[key] = null;
          }
          break;
        case 'state':
          final normalized = normalize(value, upper: true);
          if (normalized != null) {
            sanitized[key] = normalized;
          } else if (includeNulls && address.containsKey(key)) {
            sanitized[key] = null;
          }
          break;
        default:
          final normalized = normalize(value);
          if (normalized != null) {
            sanitized[key] = normalized;
          } else if (includeNulls && address.containsKey(key)) {
            sanitized[key] = null;
          }
      }
    }

    address.forEach(addField);
    return sanitized;
  }

  LocationModel _mapSingle(dynamic source) {
    if (source is Map<String, dynamic>) {
      return LocationModel.fromMap(source);
    }

    if (source is Map) {
      return LocationModel.fromMap(
        Map<String, dynamic>.from(
          source.map((key, value) => MapEntry(key.toString(), value)),
        ),
      );
    }

    if (source is List && source.isNotEmpty) {
      return _mapSingle(source.first);
    }

    throw ClientFailure.unknown('Resposta inválida ao mapear endereço.');
  }

  Never _handleDioError(
    DioException error, {
    required String fallback,
    required String notFoundMessage,
  }) {
    final status = error.response?.statusCode ?? 500;
    final message = _extractErrorMessage(
      error.response?.data,
      fallback: fallback,
    );

    if (status == 400 || status == 422) {
      throw ClientFailure.validation(message);
    }
    if (status == 404) {
      throw ClientFailure.validation(
        message.isEmpty ? notFoundMessage : message,
      );
    }
    throw ClientFailure.unknown(message);
  }

  String _extractErrorMessage(dynamic data, {required String fallback}) {
    if (data == null) return fallback;

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is List && data.isNotEmpty) {
      return _extractErrorMessage(data.first, fallback: fallback);
    }

    if (data is Map) {
      final message = data['message'] ?? data['detail'] ?? data['error'];
      if (message != null) {
        return _extractErrorMessage(message, fallback: fallback);
      }
      final errors = data['errors'] ?? data['details'];
      if (errors != null) {
        return _extractErrorMessage(errors, fallback: fallback);
      }
    }

    return fallback;
  }
}
