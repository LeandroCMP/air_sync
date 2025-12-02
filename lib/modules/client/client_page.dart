import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cpf_cnpj_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/phone_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/upper_case_input_formatter.dart';
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
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.themeGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo', style: TextStyle(color: Colors.white)),
        onPressed: () => showClientFormSheet(context, controller),
      ),
      body: SafeArea(
        child: Obx(() {
          final isInitialLoading =
              controller.isFetching.value && controller.clients.isEmpty;
          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summaryEntries = _buildClientSummaryEntries(controller);
          final sections = _buildClientSections(controller);
          final includeDeleted = controller.includeDeleted.value;
          final isFetching = controller.isFetching.value;
          final isLoadingMore = controller.isLoadingMore.value;
          final hasSections = sections.isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _ClientSearchField(controller: controller),
              ),
              if (isFetching) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshClients,
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _ClientFilterPanel(controller: controller),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: _ClientSummaryRow(
                            entries: summaryEntries,
                            selectedKey: controller.statusFilter.value,
                            onSelect: controller.setStatusFilter,
                          ),
                        ),
                      ),
                      if (hasSections)
                        SliverList(
                          delegate: SliverChildListDelegate(sections),
                        )
                      else
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyClients(
                            includeDeleted: includeDeleted,
                            hasAnyClients: controller.clients.isNotEmpty,
                            activeFilter: controller.statusFilter.value,
                            hasSearch: controller.searchTerm.value.isNotEmpty,
                            onResetFilters: () {
                              if (controller.statusFilter.value != 'all') {
                                controller.setStatusFilter('all');
                              }
                              if (controller.searchTerm.value.isNotEmpty) {
                                controller.clearSearch();
                              }
                            },
                            onCreate: () =>
                                showClientFormSheet(context, controller),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child:
                            isLoadingMore
                                ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
              ),
            ],
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
    final badges = <Widget>[];
    if (client.isDeleted) {
      badges.add(
        const _ClientBadge(
          label: 'Inativo',
          color: Colors.redAccent,
          icon: Icons.pause_circle_outline,
        ),
      );
    }

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
              if (badges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges,
                  ),
                ),
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
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UpperCaseTextFormatter()],
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
                            if (!sheetContext.mounted) return;
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
  static const TextCapitalization _defaultTextCap =
      TextCapitalization.none;

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
                textCapitalization: _defaultTextCap,
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
class _ClientFilterPanel extends StatelessWidget {
  const _ClientFilterPanel({required this.controller});

  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final includeDeleted = controller.includeDeleted.value;
      final tone = includeDeleted ? Colors.white : Colors.white70;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visão da lista',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  includeDeleted
                      ? 'Incluindo clientes inativos'
                      : 'Somente clientes ativos',
                  style: TextStyle(color: tone),
                ),
              ],
            ),
            const Spacer(),
            Switch.adaptive(
              value: includeDeleted,
              activeColor: context.themeGreen,
              onChanged: (_) => controller.toggleIncludeDeleted(),
            ),
          ],
        ),
      );
    });
  }
}

class _ClientBadge extends StatelessWidget {
  const _ClientBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSummaryRow extends StatelessWidget {
  const _ClientSummaryRow({
    required this.entries,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<_ClientSummaryInfo> entries;
  final String selectedKey;
  final void Function(String key) onSelect;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final entry = entries[index];
          final isSelected = selectedKey == entry.key;
          final baseColor = entry.color;
          final background = isSelected
              ? Color.lerp(baseColor, Colors.black, 0.5)!
              : Colors.white.withValues(alpha: 0.04);
          final borderColor = isSelected
              ? baseColor.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.05);
          return SizedBox(
            width: 150,
            child: GestureDetector(
              onTap: () => onSelect(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.icon,
                        color: Color.lerp(baseColor, Colors.white, 0.3),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClientSummaryInfo {
  const _ClientSummaryInfo({
    required this.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _ClientSection extends StatelessWidget {
  const _ClientSection({
    required this.title,
    required this.accent,
    required this.clients,
    required this.controller,
  });

  final String title;
  final Color accent;
  final List<ClientModel> clients;
  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...clients.map(
            (client) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Obx(() {
                final isDeleting = controller.deletingIds.contains(client.id);
                return _ClientCard(
                  client: client,
                  isDeleting: isDeleting,
                  onTap:
                      () => Get.toNamed('/client/details', arguments: client),
                  onEdit: () => showClientFormSheet(
                    context,
                    controller,
                    client: client,
                  ),
                  onDelete: () => _confirmDeletion(context, controller, client),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSearchField extends StatelessWidget {
  const _ClientSearchField({required this.controller});

  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasText = controller.searchTerm.value.isNotEmpty;
      return TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Buscar clientes',
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: hasText
              ? IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.clear),
                onPressed: controller.clearSearch,
              )
              : null,
        ),
      );
    });
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients({
    required this.includeDeleted,
    required this.hasAnyClients,
    required this.activeFilter,
    required this.hasSearch,
    required this.onResetFilters,
    required this.onCreate,
  });

  final bool includeDeleted;
  final bool hasAnyClients;
  final String activeFilter;
  final bool hasSearch;
  final VoidCallback onResetFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    late final String title;
    late final String subtitle;
    bool showCreateButton = true;
    bool showResetButton = false;

    if (!hasAnyClients) {
      title = 'Você ainda não tem clientes cadastrados';
      subtitle = 'Cadastre o primeiro cliente tocando no botão abaixo.';
    } else if (hasSearch) {
      title = 'Nenhum cliente encontrado para a busca atual';
      subtitle = 'Tente outro termo ou limpe a busca para ver todos.';
      showResetButton = true;
      showCreateButton = false;
    } else if (activeFilter != 'all') {
      final label = _statusFilterLabel(activeFilter);
      title = 'Nenhum cliente $label no momento';
      subtitle = 'Ajuste o filtro de "$label" ou volte a exibir todos.';
      showResetButton = true;
      showCreateButton = false;
    } else {
      title =
          includeDeleted
              ? 'Nenhum cliente corresponde aos filtros'
              : 'Você ainda não tem clientes cadastrados';
      subtitle =
          includeDeleted
              ? 'Ajuste os filtros ou tente uma nova busca.'
              : 'Cadastre o primeiro cliente tocando no botão abaixo.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 72, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (showResetButton)
            OutlinedButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          if (showResetButton && showCreateButton) const SizedBox(height: 12),
          if (showCreateButton)
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar cliente'),
            ),
        ],
      ),
    );
  }
}

List<_ClientSummaryInfo> _buildClientSummaryEntries(
  ClientController controller,
) {
  final total = controller.clients.length;
  final active = controller.clients.where((c) => !c.isDeleted).length;
  final inactive = controller.clients.where((c) => c.isDeleted).length;
  return [
    _ClientSummaryInfo(
      key: 'all',
      label: 'Todos',
      value: total.toString(),
      color: Colors.blueAccent,
      icon: Icons.people_outline,
    ),
    _ClientSummaryInfo(
      key: 'active',
      label: 'Ativos',
      value: active.toString(),
      color: Colors.tealAccent,
      icon: Icons.verified_outlined,
    ),
    _ClientSummaryInfo(
      key: 'inactive',
      label: 'Inativos',
      value: inactive.toString(),
      color: Colors.deepOrangeAccent,
      icon: Icons.block_outlined,
    ),
  ];
}

List<Widget> _buildClientSections(ClientController controller) {
  final clients = controller.clients.toList();
  final active = clients.where((c) => !c.isDeleted).toList();
  final inactive = clients.where((c) => c.isDeleted).toList();
  final filter = controller.statusFilter.value;
  final sections = <Widget>[];

  if ((filter == 'all' || filter == 'active') && active.isNotEmpty) {
    sections.add(
      _ClientSection(
        title: 'Clientes ativos',
        accent: Colors.tealAccent,
        clients: active,
        controller: controller,
      ),
    );
  }
  if ((filter == 'all' || filter == 'inactive') && inactive.isNotEmpty) {
    sections.add(
      _ClientSection(
        title: 'Clientes inativos',
        accent: Colors.deepOrangeAccent,
        clients: inactive,
        controller: controller,
      ),
    );
  }
  return sections;
}

String _statusFilterLabel(String key) {
  switch (key) {
    case 'active':
      return 'ativos';
    case 'inactive':
      return 'inativos';
    default:
      return 'todos';
  }
}
