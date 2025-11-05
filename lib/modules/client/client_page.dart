import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cpf_cnpj_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/phone_input_formatter.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'client_controller.dart';

class ClientPage extends GetView<ClientController> {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _SearchField(controller: controller),
          ),
        ),
        actions: const [_ClientFilterToggle()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.themeGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo', style: TextStyle(color: Colors.white)),
        onPressed: () => showClientFormSheet(context, controller),
      ),
      body: const _ClientList(),
    );
  }
}

class _ClientFilterToggle extends StatelessWidget {
  const _ClientFilterToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<ClientController>();
      final includeDeleted = controller.includeDeleted.value;
      return IconButton(
        tooltip:
            includeDeleted ? 'Exibindo clientes inativos' : 'Ocultar inativos',
        icon: Icon(
          includeDeleted ? Icons.visibility : Icons.visibility_off,
          color: Colors.white,
        ),
        onPressed: controller.toggleIncludeDeleted,
      );
    });
  }
}

class _ClientList extends StatelessWidget {
  const _ClientList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<ClientController>();
      final items = controller.clients;
      final isLoadingInitial =
          controller.isFetching.value && controller.clients.isEmpty;

      if (isLoadingInitial) {
        return const Center(child: CircularProgressIndicator());
      }

      if (items.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.refreshClients,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 72,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum cliente encontrado',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                controller.includeDeleted.value
                    ? 'Ajuste os filtros ou cadastre um novo cliente.'
                    : 'Cadastre um novo cliente usando o botão abaixo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => showClientFormSheet(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar cliente'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          const SizedBox(height: 8),
          const _ClientSummary(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshClients,
              child: ListView.separated(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final client = items[index];
                  return Obx(() {
                    final isDeleting = controller.deletingIds.contains(
                      client.id,
                    );
                    return _ClientCard(
                      client: client,
                      isDeleting: isDeleting,
                      onTap:
                          () =>
                              Get.toNamed('/client/details', arguments: client),
                      onEdit:
                          () => showClientFormSheet(
                            context,
                            controller,
                            client: client,
                          ),
                      onDelete:
                          () => _confirmDeletion(context, controller, client),
                    );
                  });
                },
              ),
            ),
          ),
          Obx(() {
            if (!controller.isLoadingMore.value) {
              return const SizedBox.shrink();
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            );
          }),
        ],
      );
    });
  }
}

class _ClientSummary extends StatelessWidget {
  const _ClientSummary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<ClientController>();
      final includeDeleted = controller.includeDeleted.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FilterChip(
              label: Text(
                includeDeleted ? 'Exibindo inativos' : 'Somente ativos',
              ),
              selected: includeDeleted,
              onSelected: (_) => controller.toggleIncludeDeleted(),
            ),
            const SizedBox(width: 12),
            Chip(
              avatar: const Icon(Icons.people, size: 18),
              label: Text('${controller.clients.length} cliente(s)'),
            ),
          ],
        ),
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.onSearchChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.themeLightGray,
        hintText: 'Buscar por nome ou documento',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: Obx(() {
          if (controller.searchTerm.value.isEmpty) {
            return const SizedBox.shrink();
          }
          return IconButton(
            tooltip: 'Limpar busca',
            icon: const Icon(Icons.clear, color: Colors.white70),
            onPressed: controller.clearSearch,
          );
        }),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });

  final ClientModel client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = client.docNumber?.trim();
    final primaryPhone = client.primaryPhone;
    final primaryEmail = client.primaryEmail;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDeleting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (client.isDeleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Inativo',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (doc != null && doc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            doc,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isDeleting)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    PopupMenuButton<_ClientAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _ClientAction.edit:
                            onEdit();
                            break;
                          case _ClientAction.delete:
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: _ClientAction.edit,
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: _ClientAction.delete,
                              child: Text('Excluir'),
                            ),
                          ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (primaryPhone.isNotEmpty)
                _InfoRow(icon: Icons.phone, value: primaryPhone),
              if (primaryEmail.isNotEmpty)
                _InfoRow(icon: Icons.email_outlined, value: primaryEmail),
              if (client.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      client.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                ),
              ],
              if (client.notes != null && client.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(client.notes!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _ClientAction { edit, delete }

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

Future<void> showClientFormSheet(
  BuildContext context,
  ClientController controller, {
  ClientModel? client,
}) async {
  if (client == null) {
    controller.startCreate();
  } else {
    controller.startEdit(client);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: bottom + 24,
        ),
        child: _ClientForm(controller: controller, sheetContext: sheetContext),
      );
    },
  );

  controller.cancelForm();
}

class _ClientForm extends StatelessWidget {
  const _ClientForm({required this.controller, required this.sheetContext});

  final ClientController controller;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.editingClient.value != null;
      final loading = controller.isLoading.value;
      return Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Editar cliente' : 'Novo cliente',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed:
                        loading
                            ? null
                            : () {
                              controller.cancelForm();
                              if (Get.isBottomSheetOpen ?? false) {
                                Get.back();
                              } else if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome*'),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.docController,
                decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CpfCnpjInputFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _ListInputSection(
                label: 'Telefones',
                controller: controller.phoneInputController,
                items: controller.phones,
                keyboardType: TextInputType.phone,
                formatter: PhoneInputFormatter(),
                validator: controller.validatePhone,
                onAdd: controller.addPhone,
                onRemove: controller.removePhone,
                hint: '(11) 99999-9999',
              ),
              const SizedBox(height: 12),
              _ListInputSection(
                label: 'E-mails',
                controller: controller.emailInputController,
                items: controller.emails,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
                onAdd: controller.addEmail,
                onRemove: controller.removeEmail,
                hint: 'contato@empresa.com',
                allowDuplicates: false,
              ),
              const SizedBox(height: 12),
              _ContactsValidator(controller: controller),
              const SizedBox(height: 12),
              _ListInputSection(
                label: 'Etiquetas',
                controller: controller.tagInputController,
                items: controller.tags,
                onAdd: controller.addTag,
                onRemove: controller.removeTag,
                hint: 'vip, manutenção, etc.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.npsController,
                decoration: const InputDecoration(labelText: 'NPS (0 a 10)'),
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                validator: controller.validateNps,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.notesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : () async {
                            final success = await controller.saveClient();
                            if (success) {
                              if (Get.isBottomSheetOpen ?? false) {
                                Get.back();
                              } else if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                            }
                          },
                  icon:
                      loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check),
                  label: Text(
                    loading
                        ? 'Salvando...'
                        : (isEditing ? 'Salvar alterações' : 'Cadastrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ListInputSection extends StatelessWidget {
  const _ListInputSection({
    required this.label,
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.hint,
    this.keyboardType,
    this.formatter,
    this.validator,
    this.allowDuplicates = true,
  });

  final String label;
  final TextEditingController controller;
  final RxList<String> items;
  final void Function([String? value]) onAdd;
  final void Function(String value) onRemove;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputFormatter? formatter;
  final String? Function(String?)? validator;
  final bool allowDuplicates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters:
                    formatter != null ? <TextInputFormatter>[formatter!] : null,
                decoration: InputDecoration(hintText: hint),
                style: const TextStyle(color: Colors.white),
                validator: validator,
                onFieldSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isEmpty) return;
                  if (!allowDuplicates && items.contains(trimmed)) {
                    controller.clear();
                    return;
                  }
                  onAdd(trimmed);
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                if (!allowDuplicates && items.contains(value)) {
                  controller.clear();
                  return;
                }
                onAdd(value);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (value) => InputChip(
                        label: Text(value),
                        onDeleted: () => onRemove(value),
                      ),
                    )
                    .toList(),
          );
        }),
      ],
    );
  }
}

class _ContactsValidator extends StatelessWidget {
  const _ContactsValidator({required this.controller});

  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<void>(
      validator: (_) {
        if (controller.phones.isEmpty && controller.emails.isEmpty) {
          return 'Informe ao menos um telefone ou e-mail';
        }
        return null;
      },
      builder: (field) {
        if (!field.hasError) {
          return const SizedBox.shrink();
        }
        return Text(
          field.errorText!,
          style: const TextStyle(color: Colors.redAccent),
        );
      },
    );
  }
}

Future<void> _confirmDeletion(
  BuildContext context,
  ClientController controller,
  ClientModel client,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text(
          'Tem certeza de que deseja remover o cliente "${client.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await controller.deleteClient(client);
  }
}
