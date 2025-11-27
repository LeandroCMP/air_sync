import 'dart:async';

import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuppliersController extends GetxController
    with LoaderMixin, MessagesMixin {
  final SuppliersService _service;
  SuppliersController({required SuppliersService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <SupplierModel>[].obs;
  final searchCtrl = TextEditingController();
  final deletingIds = <String>{}.obs;
  final RxString searchTerm = ''.obs;
  final RxString statusFilter = 'all'.obs;
  Timer? _searchDebounce;

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    await load();
    super.onInit();
  }

  Future<void> load({String? text}) async {
    final filter = (text ?? searchTerm.value).trim();
    isLoading(true);
    try {
      final list = await _service.list(text: filter.isEmpty ? null : filter);
      items.assignAll(list.map(_normalizeSupplier));
    } finally {
      isLoading(false);
    }
  }

  Future<bool> create({
    required String name,
    String? docNumber,
    String? phone,
    String? email,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final normalizedName = _upperRequired(name);
      final s = await _service.create(
        name: normalizedName,
        docNumber: docNumber,
        phone: phone,
        email: email,
        notes: notes,
      );
      items.insert(0, _normalizeSupplier(s));
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Fornecedor "${s.name}" cadastrado.',
        ),
      );
      return true;
    } catch (e) {
      message(
        MessageModel.error(title: 'Erro', message: 'Falha ao criar fornecedor'),
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateSupplier(String id, Map<String, dynamic> fields) async {
    isLoading(true);
    try {
      final payload = Map<String, dynamic>.from(fields);
      if (payload['name'] is String) {
        payload['name'] = _upperRequired(payload['name'] as String);
      }
      await _service.update(id, payload);
      final idx = items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final old = items[idx];
        final updated = SupplierModel(
          id: old.id,
          name: (payload['name'] ?? old.name) as String,
          docNumber: (payload['docNumber'] ?? old.docNumber) as String?,
          phone: (payload['phone'] ?? old.phone) as String?,
          email: (payload['email'] ?? old.email) as String?,
          notes: (payload['notes'] ?? old.notes) as String?,
        );
        items[idx] = _normalizeSupplier(updated);
      }
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Fornecedor atualizado.',
        ),
      );
      return true;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao atualizar fornecedor',
        ),
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> delete(String id) async {
    if (deletingIds.contains(id)) {
      return false;
    }
    deletingIds.add(id);
    deletingIds.refresh();
    try {
      await _service.delete(id);
      items.removeWhere((e) => e.id == id);
      message(
        MessageModel.success(title: 'Sucesso', message: 'Fornecedor removido.'),
      );
      return true;
    } catch (e) {
      if (e is dio.DioException) {
        final code = e.response?.statusCode ?? 0;
        String msg = 'Falha ao remover fornecedor';
        if (code == 401) {
          msg = 'Sessao expirada';
        } else if (code == 403) {
          msg = 'Sem permissao para excluir';
        } else if (code == 409 || code == 400) {
          msg = 'Conflito: fornecedor vinculado a registros';
        } else if (code == 422) {
          msg = 'Operacao nao permitida';
        }
        message(MessageModel.error(title: 'Erro', message: msg));
      } else {
        message(
          MessageModel.error(
            title: 'Erro',
            message: 'Falha ao remover fornecedor',
          ),
        );
      }
      return false;
    } finally {
      deletingIds.remove(id);
      deletingIds.refresh();
    }
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    searchTerm.value = normalized;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      load(text: normalized);
    });
  }

  void clearSearch() {
    searchCtrl.clear();
    onSearchChanged('');
  }

  void setStatusFilter(String value) {
    if (statusFilter.value == value) {
      statusFilter.value = 'all';
    } else {
      statusFilter.value = value;
    }
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  String _upperRequired(String value) => value.trim().toUpperCase();

  SupplierModel _normalizeSupplier(SupplierModel supplier) => SupplierModel(
        id: supplier.id,
        name: supplier.name.trim().toUpperCase(),
        docNumber: supplier.docNumber,
        phone: supplier.phone,
        email: supplier.email,
        notes: supplier.notes,
      );
}
