import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';

class SuppliersController extends GetxController
    with LoaderMixin, MessagesMixin {
  final SuppliersService _service;
  SuppliersController({required SuppliersService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <SupplierModel>[].obs;
  final searchCtrl = TextEditingController();
  final deletingIds = <String>{}.obs;

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    await load();
    super.onInit();
  }

  Future<void> load({String? text}) async {
    isLoading(true);
    try {
      final list = await _service.list(text: text);
      items.assignAll(list);
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
      final s = await _service.create(
        name: name,
        docNumber: docNumber,
        phone: phone,
        email: email,
        notes: notes,
      );
      items.insert(0, s);
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
      await _service.update(id, fields);
      final idx = items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final old = items[idx];
        final updated = SupplierModel(
          id: old.id,
          name: (fields['name'] ?? old.name) as String,
          docNumber: (fields['docNumber'] ?? old.docNumber) as String?,
          phone: (fields['phone'] ?? old.phone) as String?,
          email: (fields['email'] ?? old.email) as String?,
          notes: (fields['notes'] ?? old.notes) as String?,
        );
        items[idx] = updated;
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
}
