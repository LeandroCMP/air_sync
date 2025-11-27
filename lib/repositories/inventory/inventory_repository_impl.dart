import 'dart:convert';

import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/inventory_category_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/inventory_rebalance_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _api = Get.find<ApiClient>();
  String _upper(String value) => value.trim().toUpperCase();

  static const _itemsEndpoint = '/v1/inventory/items';
  static const _legacyItemsEndpoint = '/v1/inventory/items';
  static const _inventoryMovementsEndpoint = '/v1/inventory/movements';
  static const _stockEndpoint = '/v1/stock';
  static const _categoriesEndpoint = '/v1/inventory/categories';

  List<InventoryItemModel> _mapItemList(dynamic data) {
    Iterable<dynamic>? rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final items = data['items'] ?? data['data'] ?? data['results'];
      if (items is List) {
        rawList = items;
      }
    }

    if (rawList == null) return [];

    final list = <InventoryItemModel>[];
    for (final row in rawList) {
      try {
        final e = Map<String, dynamic>.from(row as Map);
        list.add(
          InventoryItemModel.fromMap((e['id'] ?? e['_id'] ?? '').toString(), e),
        );
      } catch (_) {
        // ignora item malformado
      }
    }
    return list;
  }

  List<StockMovementModel> _mapMovementList(dynamic data) {
    Iterable<dynamic>? rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final items =
          data['items'] ?? data['movements'] ?? data['data'] ?? data['results'];
      if (items is List) {
        rawList = items;
      }
    }
    if (rawList == null) return [];

    final list = <StockMovementModel>[];
    for (final row in rawList) {
      try {
        final e = Map<String, dynamic>.from(row as Map);
        list.add(StockMovementModel.fromMap(e));
      } catch (_) {
        // ignora movimento malformado
      }
    }
    return list;
  }

  bool _shouldFallback(int statusCode) =>
      statusCode == 404 || statusCode == 405;

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    String? bestMessage;

    String? pickDetail(dynamic source) {
      if (source is List) {
        for (final entry in source) {
          final detail = pickDetail(entry);
          if (detail != null && detail.trim().isNotEmpty) {
            return detail;
          }
        }
      } else if (source is Map) {
        final field = source['field'] ?? source['property'] ?? source['path'];
        final detail =
            source['message'] ?? source['detail'] ?? source['reason'];
        if (detail is String && detail.trim().isNotEmpty) {
          final text = detail.trim();
          if (field is String && field.isNotEmpty) {
            return '$field: $text';
          }
          return text;
        }
        final constraints = source['constraints'];
        if (constraints is Map) {
          final combined = constraints.values
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .join(' | ');
          if (combined.isNotEmpty) {
            if (field is String && field.isNotEmpty) {
              return '$field: $combined';
            }
            return combined;
          }
        }
        final nested = source['errors'] ?? source['details'];
        final fromNested = pickDetail(nested);
        if (fromNested != null) return fromNested;
      } else if (source is String && source.trim().isNotEmpty) {
        return source;
      }
      return null;
    }

    if (data is Map) {
      bestMessage = pickDetail(data['errors']) ?? pickDetail(data['details']);
      bestMessage ??=
          pickDetail(data['message']) ??
          pickDetail(data['error']) ??
          pickDetail(data['detail']);
      if ((bestMessage == null || bestMessage.trim().isEmpty) &&
          data['code'] != null &&
          data['message'] != null) {
        bestMessage = '${data['message']}';
      }
    } else if (data is List && data.isNotEmpty) {
      bestMessage = pickDetail(data);
    } else if (data is String && data.isNotEmpty) {
      bestMessage = data;
    }

    if (bestMessage != null && bestMessage.trim().isNotEmpty) {
      return bestMessage.trim();
    }

    final status = e.response?.statusCode;
    if (status == 409 && e.response?.statusMessage != null) {
      return e.response!.statusMessage!;
    }

    if (data is Map && data['code'] != null) {
      return jsonEncode(data);
    }

    if (data is List && data.isNotEmpty) {
      return data.first.toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data != null) {
      return jsonEncode(data);
    }
    return fallback;
  }

  @override
  Future<List<InventoryItemModel>> getItems({
    String? userId,
    String text = '',
    int? page,
    int? limit,
    bool? belowMin,
  }) async {
    final query = text.trim();
    final params = query.isEmpty ? null : {'text': query};

    try {
      final res = await _api.dio.get(
        _itemsEndpoint,
        queryParameters: params,
      );
      final items = _mapItemList(res.data);
      return _applyInventoryFilters(
        items,
        belowMin: belowMin,
        page: page,
        limit: limit,
      );
    } catch (_) {
      // Evita derrubar a tela por erro de parsing/validação.
      return const [];
    }
  }

  @override
  Future<InventoryItemModel> registerItem({
    required String name,
    required String sku,
    required double minQty,
    String? barcode,
    String? unit,
    double? maxQty,
    String? supplierId,
    double? avgCost,
    double? sellPrice,
    String? categoryId,
    double? markupPercent,
    String? pricingMode,
  }) async {
    final trimmedName = name.trim();
    final trimmedSku = sku.trim();
    if (trimmedName.isEmpty || trimmedSku.isEmpty) {
      throw InventoryFailure.validation('Nome e SKU são obrigatórios');
    }
    if (minQty < 0) {
      throw InventoryFailure.validation('Estoque mínimo inválido');
    }

    final unitTrimmed = (unit ?? '').trim();
    final baseUnit = unitTrimmed.isNotEmpty ? unitTrimmed : 'UN';
    final normalizedName = _upper(trimmedName);
    final normalizedSku = _upper(trimmedSku);
    final normalizedUnit = _upper(baseUnit);

    final legacyPayload = <String, dynamic>{
      'name': normalizedName,
      'sku': normalizedSku,
      'minQty': minQty,
      'unit': normalizedUnit,
    };
    final trimmedBarcode = (barcode ?? '').trim();
    if (trimmedBarcode.isNotEmpty) {
      legacyPayload['barcode'] = trimmedBarcode;
    }
    if (maxQty != null) {
      legacyPayload['maxQty'] = maxQty;
    }
    final trimmedSupplier = (supplierId ?? '').trim();
    if (trimmedSupplier.isNotEmpty) {
      legacyPayload['supplierId'] = trimmedSupplier;
    }
    if (avgCost != null) {
      legacyPayload['avgCost'] = avgCost;
    }
    if (sellPrice != null) {
      legacyPayload['sellPrice'] = sellPrice;
    }

    final pricingModeTrimmed = (pricingMode ?? '').trim();
    final pricingModeNormalized =
        pricingModeTrimmed.isEmpty ? null : pricingModeTrimmed;
    final trimmedCategory = (categoryId ?? '').trim();
    final newPayload = <String, dynamic>{
      'name': normalizedName,
      'description': normalizedName,
      'sku': normalizedSku,
      'minQuantity': minQty,
      'unit': normalizedUnit,
      if (trimmedBarcode.isNotEmpty) 'barcode': trimmedBarcode,
      if (maxQty != null) 'maxQty': maxQty,
      if (trimmedSupplier.isNotEmpty) 'supplierId': trimmedSupplier,
      if (avgCost != null) 'avgCost': avgCost,
      if (sellPrice != null) 'sellPrice': sellPrice,
      if (trimmedCategory.isNotEmpty) 'categoryId': trimmedCategory,
      if (markupPercent != null) 'markupPercent': markupPercent,
      if (pricingModeNormalized != null) 'pricingMode': pricingModeNormalized,
    };

    try {
      final legacyRes = await _api.dio.post(
        _legacyItemsEndpoint,
        data: legacyPayload,
      );
      final data = Map<String, dynamic>.from(legacyRes.data as Map);
      final id = (data['id'] ?? data['_id'] ?? '').toString();
      return InventoryItemModel.fromMap(id, data);
    } on DioException catch (legacyError) {
      final legacyStatus = legacyError.response?.statusCode ?? 0;
      if (_shouldFallback(legacyStatus)) {
        try {
          final response = await _api.dio.post(
            _itemsEndpoint,
            data: newPayload,
          );
          final data = Map<String, dynamic>.from(response.data as Map);
          final id = (data['id'] ?? data['_id'] ?? '').toString();
          return InventoryItemModel.fromMap(id, data);
        } on DioException catch (e) {
          final message = _extractErrorMessage(e, 'Erro ao registrar item');
          throw InventoryFailure.validation(message);
        }
      }
      final message = _extractErrorMessage(
        legacyError,
        'Erro ao registrar item',
      );
      if (legacyStatus == 400 || legacyStatus == 422 || legacyStatus == 409) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao cadastrar item');
    }
  }

  @override
  Future<void> updateItem(InventoryItemModel item) async {
    if (item.id.isEmpty) {
      throw InventoryFailure.validation(
        'ID do item é obrigatório para atualização',
      );
    }

    final normalizedDescription = _upper(item.description);
    final unitNormalized =
        _upper(item.unit.isNotEmpty ? item.unit : 'UN');

    final legacyPayload = {
      'description': normalizedDescription,
      'unit': unitNormalized,
      'quantity': item.quantity,
    };

    final newPayload = {
      'name': normalizedDescription,
      'unit': unitNormalized,
      'minQuantity': item.minQuantity,
      'active': item.active,
    };

    try {
      await _api.dio.patch(
        '$_legacyItemsEndpoint/${item.id}',
        data: legacyPayload,
      );
    } on DioException catch (legacyError) {
      final legacyStatus = legacyError.response?.statusCode ?? 0;
      if (_shouldFallback(legacyStatus)) {
        try {
          await _api.dio.patch('$_itemsEndpoint/${item.id}', data: newPayload);
          return;
        } on DioException catch (e) {
          final message = _extractErrorMessage(e, 'Erro ao atualizar item');
          throw InventoryFailure.validation(message);
        }
      }
      final message = _extractErrorMessage(
        legacyError,
        'Erro ao atualizar item',
      );
      if (legacyStatus == 400 || legacyStatus == 422 || legacyStatus == 409) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao atualizar item');
    }
  }

  @override
  Future<void> addRecord({
    required String itemId,
    required double quantityToAdd,
  }) async {
    final payload = {'itemId': itemId, 'type': 'in', 'qty': quantityToAdd};
    try {
      await _api.dio.post(_inventoryMovementsEndpoint, data: payload);
    } on DioException catch (e) {
      throw InventoryFailure.firebase(
        'Erro ao adicionar registro: ${_extractErrorMessage(e, e.message ?? 'falha')}',
      );
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao registrar entrada');
    }
  }

  @override
  Future<void> deleteEntry({
    required String itemId,
    required String entryId,
  }) async {
    try {
      await _api.dio.delete('$_legacyItemsEndpoint/$itemId/entries/$entryId');
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
        throw InventoryFailure.validation(
          'ID do item é obrigatório para exclusão',
        );
      }
      await _api.dio
          .delete('$_legacyItemsEndpoint/$itemId')
          .timeout(const Duration(seconds: 12));
    } on DioException catch (legacyError) {
      final legacyStatus = legacyError.response?.statusCode ?? 0;
      if (_shouldFallback(legacyStatus)) {
        try {
          await _api.dio
              .delete('$_itemsEndpoint/$itemId')
              .timeout(const Duration(seconds: 12));
          return;
        } on DioException catch (e) {
          final message = _extractErrorMessage(e, 'Erro ao deletar item');
          throw InventoryFailure.validation(message);
        }
      }
      final message = _extractErrorMessage(legacyError, 'Erro ao deletar item');
      if (legacyStatus == 400 || legacyStatus == 422 || legacyStatus == 409) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao deletar item');
    }
  }

  // Spec-compliant endpoints
  @override
  Future<List<InventoryItemModel>> listItems({
    String? q,
    bool? active,
    bool? belowMin,
    int? page,
    int? limit,
  }) async {
    final query = (q ?? '').trim();
    final params = query.isEmpty ? null : {'text': query};

    try {
      final res = await _api.dio.get(
        _itemsEndpoint,
        queryParameters: params,
      );
      final items = _mapItemList(res.data);
      return _applyInventoryFilters(
        items,
        active: active,
        belowMin: belowMin,
        page: page,
        limit: limit,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final message = _extractErrorMessage(e, 'Erro ao carregar itens de estoque');
      if (status == 400 || status == 404 || status == 409 || status == 422) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown(
        'Erro inesperado ao carregar itens de estoque',
      );
    }
  }

  @override
  Future<InventoryItemModel> getItem(String id) async {
    try {
      final res = await _api.dio.get(
        _itemsEndpoint,
        queryParameters: {'text': id},
      );
      final items = _mapItemList(res.data);
      if (items.isEmpty) {
        throw InventoryFailure.validation('Item n?o encontrado');
      }
      for (final item in items) {
        if (item.id == id) return item;
      }
      return items.first;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final message = _extractErrorMessage(e, 'Erro ao buscar item');
      if (status == 400 || status == 404 || status == 409 || status == 422) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao buscar item');
    }
  }

  List<InventoryItemModel> _applyInventoryFilters(
    List<InventoryItemModel> source, {
    bool? active,
    bool? belowMin,
    int? page,
    int? limit,
  }) {
    Iterable<InventoryItemModel> filtered = source;
    if (active != null) {
      filtered = filtered.where((item) => item.active == active);
    }
    if (belowMin == true) {
      filtered =
          filtered.where((item) => item.quantity <= item.minQuantity);
    }
    final list = filtered.toList();
    if (limit != null && limit > 0) {
      final currentPage = (page ?? 1).clamp(1, double.infinity).toInt();
      final start = (currentPage - 1) * limit;
      if (start >= list.length) return const [];
      final end = (start + limit) > list.length ? list.length : start + limit;
      return list.sublist(start, end);
    }
    return list;
  }

  @override
  Future<void> patchItem(String id, Map<String, dynamic> changes) async {
    try {
      if (changes.isEmpty) {
        return;
      }

      final payload = <String, dynamic>{};
      final legacyPayload = <String, dynamic>{};
      var hasLegacyData = false;

      void addLegacy(String key, dynamic value) {
        legacyPayload[key] = value;
        hasLegacyData = true;
      }

      changes.forEach((key, dynamic value) {
        switch (key) {
          case 'name':
            if (value != null) {
              final upperValue = _upper(value.toString());
              payload['name'] = upperValue;
              addLegacy('name', upperValue);
              addLegacy('description', upperValue);
            }
            break;
          case 'description':
            if (value != null) {
              final upperValue = _upper(value.toString());
              payload['description'] = upperValue;
              addLegacy('description', upperValue);
            }
            break;
          case 'sku':
            if (value != null) {
              final upperSku = _upper(value.toString());
              payload['sku'] = upperSku;
              addLegacy('sku', upperSku);
            }
            break;
          case 'unit':
            if (value != null) {
              final normalized = _upper(value.toString());
              payload['unit'] = normalized;
              addLegacy('unit', normalized);
            }
            break;
          case 'minQty':
            payload['minQty'] = value;
            addLegacy('minQty', value);
            break;
          case 'active':
            payload['active'] = value;
            addLegacy('active', value);
            break;
          case 'barcode':
          case 'maxQty':
          case 'supplierId':
          case 'avgCost':
          case 'sellPrice':
            if (value != null) {
              payload[key] = value;
              addLegacy(key, value);
            }
            break;
          default:
            payload[key] = value;
        }
      });

      if (payload.isEmpty) {
        return;
      }

      if (hasLegacyData) {
        try {
          await _api.dio.patch(
            '$_legacyItemsEndpoint/$id',
            data: legacyPayload,
          );
          return;
        } on DioException catch (legacyError) {
          final legacyStatus = legacyError.response?.statusCode ?? 0;
          if (!_shouldFallback(legacyStatus)) {
            final message = _extractErrorMessage(
              legacyError,
              'Erro ao editar item',
            );
            if (legacyStatus == 400 ||
                legacyStatus == 422 ||
                legacyStatus == 409) {
              throw InventoryFailure.validation(message);
            }
            throw InventoryFailure.firebase(message);
          }
        }
      }

      await _api.dio.patch('$_itemsEndpoint/$id', data: payload);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final message = _extractErrorMessage(e, 'Erro ao editar item');
      if (status == 400 || status == 422 || status == 409) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao editar item');
    }
  }

  @override
  Future<List<StockLevelModel>> getStockLevels({
    String? itemId,
    String? locationId,
  }) async {
    try {
      final qp = <String, dynamic>{};
      if ((itemId ?? '').isNotEmpty) qp['itemId'] = itemId;
      if ((locationId ?? '').isNotEmpty) qp['locationId'] = locationId;
      final res = await _api.dio.get(
        '$_stockEndpoint/levels',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final data = res.data;
      if (data is List) {
        return data
            .map(
              (e) =>
                  StockLevelModel.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      if (data is Map) {
        return [StockLevelModel.fromMap(Map<String, dynamic>.from(data))];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<StockMovementModel>> listMovements({
    required String itemId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (itemId.isEmpty) return [];
    final params = <String, dynamic>{'itemId': itemId};
    if (limit != null) params['limit'] = limit;
    if (startDate != null) {
      params['from'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      params['to'] = endDate.toUtc().toIso8601String();
    }

    try {
      final res = await _api.dio.get(
        _inventoryMovementsEndpoint,
        queryParameters: params,
      );
      final list = _mapMovementList(res.data);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (_shouldFallback(status)) {
        return [];
      }
      final message = _extractErrorMessage(
        e,
        'Erro ao buscar histórico de movimentos',
      );
      if (status == 400 || status == 422) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      return [];
    }
  }

  String _movementTypeToInventoryMovement(MovementType t) {
    switch (t) {
      case MovementType.receive:
      case MovementType.adjustPos:
      case MovementType.returnIn:
      case MovementType.transferIn:
        return 'in';
      case MovementType.issue:
      case MovementType.adjustNeg:
      case MovementType.transferOut:
        return 'out';
    }
  }

  @override
  Future<StockMovementModel> createMovement({
    required String itemId,
    String? locationId,
    required double quantity,
    required MovementType type,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'itemId': itemId,
      'type': _movementTypeToInventoryMovement(type),
      'qty': quantity,
      if ((reason ?? '').isNotEmpty) 'ref': reason,
      if ((documentRef ?? '').isNotEmpty) 'lot': documentRef,
      if ((idempotencyKey ?? '').isNotEmpty) 'refId': idempotencyKey,
    };

    try {
      await _api.dio.post(_inventoryMovementsEndpoint, data: payload);
      return StockMovementModel(
        id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
        itemId: itemId,
        locationId: locationId,
        quantity: quantity,
        type: type,
        reason: reason,
        documentRef: documentRef,
        idempotencyKey: idempotencyKey,
        performedBy: null,
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw InventoryFailure.firebase(
        'Erro ao criar movimento: ${_extractErrorMessage(e, e.message ?? 'falha')}',
      );
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado ao criar movimento');
    }
  }

  @override
  Future<void> transferStock({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required double quantity,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  }) async {
    final outPayload = {
      'itemId': itemId,
      'type': 'out',
      'qty': quantity,
      if ((reason ?? '').isNotEmpty) 'ref': reason,
      if ((documentRef ?? '').isNotEmpty) 'lot': documentRef,
      if ((idempotencyKey ?? '').isNotEmpty) 'refId': idempotencyKey,
    };
    final inPayload = {
      'itemId': itemId,
      'type': 'in',
      'qty': quantity,
      if ((reason ?? '').isNotEmpty) 'ref': reason,
      if ((documentRef ?? '').isNotEmpty) 'lot': documentRef,
      if ((idempotencyKey ?? '').isNotEmpty) 'refId': idempotencyKey,
    };
    try {
      await _api.dio.post(_inventoryMovementsEndpoint, data: outPayload);
      await _api.dio.post(_inventoryMovementsEndpoint, data: inPayload);
    } on DioException catch (e) {
      throw InventoryFailure.firebase(
        'Erro ao transferir: ${_extractErrorMessage(e, e.message ?? 'falha')}',
      );
    } catch (_) {
      throw InventoryFailure.unknown('Erro inesperado na transferência');
    }
  }

  @override
  Future<List<InventoryCostHistoryEntry>> getCostHistory(String id) async {
    try {
      final res = await _api.dio
          .get('$_itemsEndpoint/$id/cost-history')
          .timeout(const Duration(seconds: 12));
      final data = res.data;
      final list = <InventoryCostHistoryEntry>[];
      Iterable<dynamic>? raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        raw = data['items'] ?? data['data'] ?? data['results'];
      }
      for (final entry in raw ?? const []) {
        if (entry is Map) {
          try {
            list.add(
              InventoryCostHistoryEntry.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            );
          } catch (_) {}
        }
      }
      return list;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final message = _extractErrorMessage(
        e,
        'Erro ao buscar histórico de custo',
      );
      if (status == 400 || status == 404) {
        throw InventoryFailure.validation(message);
      }
      throw InventoryFailure.firebase(message);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<InventoryCategoryModel>> listCategories({String? search}) async {
    try {
      final searchTrimmed = (search ?? '').trim();
      final res = await _api.dio.get(
        _categoriesEndpoint,
        queryParameters: searchTrimmed.isEmpty ? null : {'q': searchTrimmed},
      );
      final data = res.data;
      Iterable<dynamic>? raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        raw = data['items'] ?? data['data'] ?? data['results'];
      }
      final list = <InventoryCategoryModel>[];
      for (final entry in raw ?? const []) {
        if (entry is Map) {
          try {
            list.add(
              InventoryCategoryModel.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            );
          } catch (_) {}
        }
      }
      return list;
    } on DioException catch (_) {
      return [];
    }
  }

  @override
  Future<InventoryCategoryModel> createCategory({
    required String name,
    required double markupPercent,
    String? description,
  }) async {
    final payload = {
      'name': name.trim(),
      'markupPercent': markupPercent,
      if ((description ?? '').trim().isNotEmpty) 'description': description,
    };
    final res = await _api.dio
        .post(_categoriesEndpoint, data: payload)
        .timeout(const Duration(seconds: 12));
    return InventoryCategoryModel.fromMap(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  @override
  Future<InventoryCategoryModel> updateCategory({
    required String id,
    String? name,
    double? markupPercent,
    String? description,
  }) async {
    final payload = <String, dynamic>{};
    final nameTrimmed = (name ?? '').trim();
    if (nameTrimmed.isNotEmpty) payload['name'] = nameTrimmed;
    if (markupPercent != null) payload['markupPercent'] = markupPercent;
    if (description != null) payload['description'] = description;
    final res = await _api.dio
        .patch('$_categoriesEndpoint/$id', data: payload)
        .timeout(const Duration(seconds: 12));
    return InventoryCategoryModel.fromMap(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _api.dio
        .delete('$_categoriesEndpoint/$id')
        .timeout(const Duration(seconds: 12));
  }

  @override
  Future<List<InventoryRebalanceSuggestion>> rebalance({int days = 30}) async {
    try {
      final res = await _api.dio.get(
        '/v1/inventory/rebalance',
        queryParameters: {'days': days},
      );
      final data = res.data;
      Iterable<dynamic> rawSuggestions = const [];
      if (data is List) {
        rawSuggestions = data;
      } else if (data is Map) {
        final items = data['items'] ?? data['data'] ?? data['results'];
        if (items is List) {
          rawSuggestions = items;
        }
      }
      return rawSuggestions
          .whereType<Map>()
          .map((e) => InventoryRebalanceSuggestion.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<InventoryRebalanceSuggestion>> purchaseForecast({
    int days = 30,
  }) async {
    try {
      final res = await _api.dio
          .post(
            '/v1/inventory/insights/forecast',
            data: const {},
          )
          .timeout(const Duration(seconds: 20));
      final data = res.data;
      Iterable<dynamic> rawSuggestions = const [];
      if (data is List) {
        rawSuggestions = data;
      } else if (data is Map) {
        final inner = data['items'] ?? data['recommendations'] ?? data['data'];
        if (inner is List) {
          rawSuggestions = inner;
        }
      }
      return rawSuggestions
          .whereType<Map>()
          .map(
            (entry) => InventoryRebalanceSuggestion.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
