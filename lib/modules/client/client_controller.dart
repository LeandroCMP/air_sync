import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:air_sync/application/core/errors/client_failure.dart';

class ClientController extends GetxController with MessagesMixin, LoaderMixin {
  ClientController({required ClientService clientService})
    : _clientService = clientService;

  final ClientService _clientService;

  static const int _pageSize = 20;

  final message = Rxn<MessageModel>();
  final isLoading = false.obs;
  final isFetching = false.obs;
  final isLoadingMore = false.obs;
  final includeDeleted = false.obs;
  final RxString statusFilter = 'all'.obs;

  final clients = <ClientModel>[].obs;

  final searchController = TextEditingController();
  final RxString searchTerm = ''.obs;

  final ScrollController scrollController = ScrollController();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final docController = TextEditingController();
  final notesController = TextEditingController();
  final phoneInputController = TextEditingController();
  final emailInputController = TextEditingController();

  final phones = <String>[].obs;
  final emails = <String>[].obs;
  final Rxn<ClientModel> editingClient = Rxn<ClientModel>();
  final deletingIds = <String>{}.obs;

  late final Worker _searchWorker;
  late final Worker _includeDeletedWorker;

  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    _searchWorker = debounce<String>(
      searchTerm,
      (_) => loadClients(reset: true),
      time: const Duration(milliseconds: 350),
    );
    _includeDeletedWorker = ever<bool>(
      includeDeleted,
      (_) => loadClients(reset: true),
    );
    scrollController.addListener(_onScroll);
    super.onInit();
  }

  @override
  void onReady() {
    loadClients(reset: true);
    super.onReady();
  }

  @override
  void onClose() {
    _searchWorker.dispose();
    _includeDeletedWorker.dispose();
    searchController.dispose();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    nameController.dispose();
    docController.dispose();
    notesController.dispose();
    phoneInputController.dispose();
    emailInputController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients ||
        isLoadingMore.value ||
        isFetching.value) {
      return;
    }
    final threshold = scrollController.position.maxScrollExtent - 200;
    if (scrollController.position.pixels >= threshold) {
      loadMore();
    }
  }

  Future<void> loadClients({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      clients.clear();
    } else {
      if (!_hasMore || isLoadingMore.value || isFetching.value) return;
    }

    final page = _currentPage;
    if (page == 1) {
      isFetching(true);
    } else {
      isLoadingMore(true);
    }

    try {
      final result = await _clientService.list(
        text: searchTerm.value.trim().isEmpty ? null : searchTerm.value.trim(),
        page: page,
        limit: _pageSize,
        includeDeleted: includeDeleted.value,
      );

      if (page == 1) {
        clients.assignAll(result);
      } else {
        final existing = clients.map((e) => e.id).toSet();
        final merged = [
          ...clients,
          ...result.where((e) => !existing.contains(e.id)),
        ];
        clients.assignAll(merged);
      }

      _hasMore = result.length == _pageSize;
      if (_hasMore) {
        _currentPage += 1;
      }
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível carregar os clientes.',
        ),
      );
    } finally {
      isFetching(false);
      isLoadingMore(false);
    }
  }

  Future<void> refreshClients() => loadClients(reset: true);

  void loadMore() => loadClients();

  void onSearchChanged(String value) => searchTerm(value);

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  void toggleIncludeDeleted() => includeDeleted.toggle();

  void setStatusFilter(String value) {
    if (statusFilter.value == value) {
      statusFilter.value = 'all';
    } else {
      statusFilter.value = value;
    }
  }

  void startCreate() {
    editingClient.value = null;
    _resetForm();
  }

  void startEdit(ClientModel client) {
    editingClient.value = client;
    _resetForm();
    nameController.text = client.name.toUpperCase();
    docController.text = client.docNumber ?? '';
    notesController.text = client.notes ?? '';
    phones.assignAll(client.phones);
    emails.assignAll(client.emails);
  }

  void cancelForm() {
    editingClient.value = null;
    _resetForm();
  }

  void addPhone([String? value]) {
    final input = (value ?? phoneInputController.text).trim();
    if (input.isEmpty) return;
    if (!phones.contains(input)) {
      phones.add(input);
    }
    phoneInputController.clear();
    formKey.currentState?.validate();
  }

  void removePhone(String value) {
    phones.remove(value);
    formKey.currentState?.validate();
  }

  void addEmail([String? value]) {
    final input = (value ?? emailInputController.text).trim();
    if (input.isEmpty) return;
    if (!emails.contains(input)) {
      emails.add(input);
    }
    emailInputController.clear();
    formKey.currentState?.validate();
  }

  void removeEmail(String value) {
    emails.remove(value);
    formKey.currentState?.validate();
  }

  String? validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Informe um telefone válido';
    }
    return null;
  }

  String? validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  Future<bool> saveClient() async {
    final form = formKey.currentState;
    if (form == null) return false;
    if (!form.validate()) return false;

    final draft = _buildClientFromForm();

    isLoading(true);
    try {
      if (editingClient.value == null) {
        final created = await _clientService.create(draft);
        clients.insert(0, created);
        message(
          MessageModel.success(
            title: 'Sucesso',
            message: 'Cliente cadastrado com sucesso.',
          ),
        );
        _resetForm();
        return true;
      } else {
        final original = editingClient.value!;
        final updated = await _clientService.update(
          draft.copyWith(id: original.id),
          original: original,
        );
        final index = clients.indexWhere((e) => e.id == updated.id);
        if (index != -1) {
          clients[index] = updated;
        }
        editingClient.value = updated;
        message(
          MessageModel.success(
            title: 'Sucesso',
            message: 'Cliente atualizado com sucesso.',
          ),
        );
        _resetForm();
        return true;
      }
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível salvar o cliente.',
        ),
      );
    } finally {
      isLoading(false);
    }
    return false;
  }

  Future<bool> deleteClient(ClientModel client) async {
    if (deletingIds.contains(client.id)) {
      return false;
    }
    deletingIds.add(client.id);
    deletingIds.refresh();
    var success = false;
    try {
      await _clientService.delete(client.id);
      clients.removeWhere((c) => c.id == client.id);
      message(
        MessageModel.success(
          title: 'Removido',
          message: 'Cliente removido com sucesso.',
        ),
      );
      success = true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível remover o cliente.',
        ),
      );
    } finally {
      deletingIds.remove(client.id);
      deletingIds.refresh();
    }
    return success;
  }

  ClientModel _buildClientFromForm() {
    final notes = notesController.text.trim();
    final doc = docController.text.trim();
    final name = _upperRequired(nameController.text);
    return ClientModel(
      id: editingClient.value?.id ?? '',
      name: name,
      docNumber: doc.isEmpty ? null : doc,
      phones: phones.toList(growable: false),
      emails: emails.toList(growable: false),
      notes: notes.isEmpty ? null : notes,
    );
  }

  void _resetForm() {
    formKey.currentState?.reset();
    nameController.clear();
    docController.clear();
    notesController.clear();
    phoneInputController.clear();
    emailInputController.clear();
    phones.clear();
    emails.clear();
  }

  String _upperRequired(String value) => value.trim().toUpperCase();

}
