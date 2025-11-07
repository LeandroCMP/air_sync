import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ignore_for_file: use_build_context_synchronously
import 'users_controller.dart';
import 'widgets/collaborator_form.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

typedef _VoidCallback = void Function();

class UsersPage extends GetView<UsersController> {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canCreate = controller.canManageCollaborators;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Colaboradores',
          style: TextStyle(color: Colors.white),
        ),
        actions: [_RoleFilterButton(controller: controller)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _UsersSearchField(controller: controller),
          ),
        ),
      ),
      floatingActionButton:
          canCreate
              ? FloatingActionButton.extended(
                backgroundColor: context.themeGreen,
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  'Novo colaborador',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => _openCollaboratorForm(context, controller),
              )
              : null,
      body: const _CollaboratorList(),
    );
  }
}

class _UsersSearchField extends StatelessWidget {
  const _UsersSearchField({required this.controller});

  final UsersController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.searchCtrl,
      builder: (context, value, _) {
        return TextField(
          controller: controller.searchCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar por nome, e-mail ou permissÃ£o',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon:
                value.text.isEmpty
                    ? null
                    : IconButton(
                      onPressed: () => controller.searchCtrl.clear(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Limpar busca',
                    ),
            filled: true,
            fillColor: context.themeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(color: context.themeBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(color: context.themeBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide(color: context.themePrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      },
    );
  }
}

class _RoleFilterButton extends StatelessWidget {
  const _RoleFilterButton({required this.controller});

  final UsersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.filterRole.value;
      return PopupMenuButton<CollaboratorRole?>(
        tooltip: 'Filtrar por papel',
        icon: const Icon(Icons.filter_list, color: Colors.white),
        onSelected: controller.applyRoleFilter,
        itemBuilder:
            (context) => [
              CheckedPopupMenuItem<CollaboratorRole?>(
                value: null,
                checked: current == null,
                child: const Text('Todos os papÃ©is'),
              ),
              ...CollaboratorRole.values.map(
                (role) => CheckedPopupMenuItem<CollaboratorRole?>(
                  value: role,
                  checked: current == role,
                  child: Text(_roleLabel(role)),
                ),
              ),
            ],
      );
    });
  }
}

class _CollaboratorList extends StatelessWidget {
  const _CollaboratorList();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.searchCtrl,
      builder: (context, value, _) {
        final query = value.text.trim().toLowerCase();
        return Obx(() {
          final isLoading = controller.isLoading.value;
          final items = controller.collaborators.toList();
          final catalogByCode = {
            for (final entry in controller.permissions) entry.code: entry,
          };
          final labelByPermission = {
            for (final entry in controller.permissions) entry.code: entry.label,
          };

          final filtered =
              query.isEmpty
                  ? items
                  : items
                      .where(
                        (collaborator) => _matchesQuery(
                          collaborator,
                          query,
                          labelByPermission,
                        ),
                      )
                      .toList();

          if (isLoading && items.isEmpty) {
            return Column(
              children: const [
                _TopLoadingIndicator(visible: true),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }

          Widget buildEmptyState() {
            return RefreshIndicator(
              onRefresh: controller.loadCollaborators,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                children: const [
                  Icon(Icons.badge_outlined, size: 72, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum colaborador cadastrado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajuste os filtros ou cadastre um novo colaborador.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          Widget buildList() {
            final roleFilter = controller.filterRole.value;
            return RefreshIndicator(
              onRefresh: controller.loadCollaborators,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CollaboratorSummary(
                      total: items.length,
                      visible: filtered.length,
                      roleFilter: roleFilter,
                    );
                  }

                  final collaborator = filtered[index - 1];
                  return Obx(() {
                    final payrollList =
                        controller.payrollByUser[collaborator.id] ??
                        const <PayrollModel>[];
                    final isPayrollLoading = controller.payrollLoading.contains(
                      collaborator.id,
                    );
                    final isDeleting = controller.deletingIds.contains(
                      collaborator.id,
                    );
                    final moduleCounts = <String, int>{};
                    for (final code in collaborator.permissions) {
                      final module =
                          catalogByCode[code]?.module?.toLowerCase() ??
                          'outros';
                      moduleCounts[module] = (moduleCounts[module] ?? 0) + 1;
                    }
                    final defaultPermissions = controller
                        .defaultPermissionsForRole(collaborator.role);
                    final usesCustomPermissions =
                        !_samePermissions(
                          defaultPermissions,
                          collaborator.permissions,
                        );

                    return _CollaboratorCard(
                      collaborator: collaborator,
                      permissionLabels: labelByPermission,
                      permissionCatalog: catalogByCode,
                      moduleCounts: moduleCounts,
                      usesCustomPermissions: usesCustomPermissions,
                      payrollCount: payrollList.length,
                      isPayrollLoading: isPayrollLoading,
                      isDeleting: isDeleting,
                      showPayrollButton: controller.canViewPayroll,
                      onEdit:
                          controller.canManageCollaborators
                              ? () => _openCollaboratorForm(
                                context,
                                controller,
                                collaborator: collaborator,
                              )
                              : null,
                      onPayroll:
                          controller.canViewPayroll
                              ? () => _openPayrollSheet(
                                context,
                                controller: controller,
                                collaborator: collaborator,
                              )
                              : null,
                      onDelete:
                          controller.canManageCollaborators
                              ? () => _confirmCollaboratorDeletion(
                                context,
                                controller,
                                collaborator,
                              )
                              : null,
                    );
                  });
                },
              ),
            );
          }

          if (filtered.isEmpty) {
            return Column(
              children: [
                _TopLoadingIndicator(visible: isLoading),
                Expanded(child: buildEmptyState()),
              ],
            );
          }

          return Column(
            children: [
              _TopLoadingIndicator(visible: isLoading),
              Expanded(child: buildList()),
            ],
          );
        });
      },
    );
  }
}

class _TopLoadingIndicator extends StatelessWidget {
  const _TopLoadingIndicator({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox(height: 0);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 4,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
        child: LinearProgressIndicator(
          color: context.themePrimary,
          backgroundColor: context.themeSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _CollaboratorSummary extends StatelessWidget {
  const _CollaboratorSummary({
    required this.total,
    required this.visible,
    required this.roleFilter,
  });

  final int total;
  final int visible;
  final CollaboratorRole? roleFilter;

  @override
  Widget build(BuildContext context) {
    final hasFilter = roleFilter != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          Chip(
            avatar: const Icon(Icons.people, size: 18),
            label: Text('$visible colaborador(es)'),
          ),
          if (visible != total)
            Chip(
              avatar: const Icon(Icons.visibility_outlined, size: 18),
              label: Text('Mostrando $visible de $total'),
            ),
          Chip(
            avatar: Icon(
              hasFilter ? Icons.filter_alt : Icons.filter_alt_off,
              size: 18,
            ),
            label: Text(
              hasFilter
                  ? 'Filtro: ${_roleLabel(roleFilter!)}'
                  : 'Sem filtro de papel',
            ),
          ),
        ],
      ),
    );
  }
}

class _CollaboratorCard extends StatelessWidget {
  const _CollaboratorCard({
    required this.collaborator,
    required this.permissionLabels,
    required this.permissionCatalog,
    required this.moduleCounts,
    required this.usesCustomPermissions,
    required this.payrollCount,
    required this.isPayrollLoading,
    required this.isDeleting,
    required this.showPayrollButton,
    this.onEdit,
    this.onPayroll,
    this.onDelete,
  });

  final CollaboratorModel collaborator;
  final Map<String, String> permissionLabels;
  final Map<String, PermissionCatalogEntry> permissionCatalog;
  final Map<String, int> moduleCounts;
  final bool usesCustomPermissions;
  final int payrollCount;
  final bool isPayrollLoading;
  final bool isDeleting;
  final bool showPayrollButton;
  final _VoidCallback? onEdit;
  final _VoidCallback? onPayroll;
  final _VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compensation = collaborator.compensation;
    final salary = compensation?.salary;
    final paymentDay = compensation?.paymentDay;
    final hourlyCost = collaborator.hourlyCost;

    final summaryEntries =
        moduleCounts.entries.toList()
          ..sort((a, b) => _moduleLabel(a.key).compareTo(_moduleLabel(b.key)));
    final summaryChips =
        summaryEntries
            .map(
              (entry) => Chip(
                label: Text('${_moduleLabel(entry.key)} · ${entry.value}'),
                backgroundColor: context.themeSurface,
              ),
            )
            .toList();

    final detailChips =
        collaborator.permissions.map((code) {
          final entry = permissionCatalog[code];
          final label = permissionLabels[code] ?? entry?.label ?? code;
          final tooltip =
              entry?.description?.trim().isNotEmpty == true
                  ? entry!.description!.trim()
                  : 'Código: $code';
          return Tooltip(
            message: tooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: Chip(
              label: Text(label),
              backgroundColor: context.themeSurface,
            ),
          );
        }).toList();

    final card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collaborator.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collaborator.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.badge, size: 18),
                      label: Text(_roleLabel(collaborator.role)),
                      backgroundColor: _roleColor(
                        collaborator.role,
                        theme,
                      ).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _roleColor(collaborator.role, theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(
                        collaborator.active ? Icons.check_circle : Icons.pause,
                        size: 18,
                        color:
                            collaborator.active
                                ? context.themeGreen
                                : theme.colorScheme.error,
                      ),
                      label: Text(
                        collaborator.active ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          color:
                              collaborator.active
                                  ? context.themeGreen
                                  : theme.colorScheme.error,
                        ),
                      ),
                      backgroundColor:
                          collaborator.active
                              ? context.themeGreen.withValues(alpha: 0.12)
                              : theme.colorScheme.error.withValues(alpha: 0.12),
                    ),
                    if (usesCustomPermissions) ...[
                      const SizedBox(height: 8),
                      Tooltip(
                        message:
                            'Permissões personalizadas para este colaborador.',
                        child: Chip(
                          avatar: const Icon(Icons.tune, size: 18),
                          label: const Text('Personalizadas'),
                          backgroundColor: theme.colorScheme.secondary
                              .withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (salary != null)
                  _InfoTile(
                    icon: Icons.attach_money,
                    label: 'Salário',
                    value: _currencyFormatter.format(salary),
                  ),
                if (hourlyCost != null)
                  _InfoTile(
                    icon: Icons.timer,
                    label: 'Custo/hora',
                    value: _currencyFormatter.format(hourlyCost),
                  ),
                if (paymentDay != null)
                  _InfoTile(
                    icon: Icons.calendar_today,
                    label: 'Dia de pagamento',
                    value: 'Dia ',
                  ),
                if (compensation?.paymentFrequency != null)
                  _InfoTile(
                    icon: Icons.event_repeat,
                    label: 'Frequência',
                    value: _paymentFrequencyLabel(
                      compensation!.paymentFrequency!,
                    ),
                  ),
                if (compensation?.paymentMethod != null)
                  _InfoTile(
                    icon: Icons.payments,
                    label: 'Forma de pagamento',
                    value: _paymentMethodLabel(compensation!.paymentMethod!),
                  ),
              ],
            ),
            if (compensation?.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                compensation!.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
            if (summaryChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Resumo de permissões',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: summaryChips),
            ],
            const SizedBox(height: 12),
            if (detailChips.isNotEmpty)
              Theme(
                data: theme.copyWith(dividerColor: Colors.white12),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: Colors.white70,
                  iconColor: Colors.white,
                  childrenPadding: const EdgeInsets.only(top: 4, bottom: 4),
                  title: Text(
                    'Permissões ()',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: detailChips,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Permissões determinadas pelo papel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onEdit != null)
                  Tooltip(
                    message: 'Editar colaborador',
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ),
                if (showPayrollButton)
                  TextButton.icon(
                    onPressed: onPayroll,
                    icon:
                        isPayrollLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      isPayrollLoading ? 'Carregando...' : 'Holerites ()',
                    ),
                  ),
                if (onDelete != null)
                  Tooltip(
                    message: 'Excluir colaborador',
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!isDeleting) {
      return card;
    }

    return Stack(
      children: [
        card,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white60,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openCollaboratorForm(
  BuildContext context,
  UsersController controller, {
  CollaboratorModel? collaborator,
}) async {
  await controller.loadPermissionCatalog();
  await controller.loadRolePresets();

  const tag = 'collaborator-form';
  if (Get.isRegistered<CollaboratorFormController>(tag: tag)) {
    Get.delete<CollaboratorFormController>(tag: tag, force: true);
  }
  final formController = Get.put(
    CollaboratorFormController(
      usersController: controller,
      collaborator: collaborator,
    ),
    tag: tag,
  );

  try {
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
          child: CollaboratorForm(
            formController: formController,
            sheetContext: sheetContext,
          ),
        );
      },
    );
  } finally {
    await Future.delayed(const Duration(milliseconds: 200));
    if (Get.isRegistered<CollaboratorFormController>(tag: tag)) {
      Get.delete<CollaboratorFormController>(tag: tag, force: true);
    }
  }
}

Future<void> _openPayrollSheet(
  BuildContext context, {
  required UsersController controller,
  required CollaboratorModel collaborator,
}) async {
  await controller.loadPayroll(collaborator.id);

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
        child: _PayrollSheet(
          controller: controller,
          collaborator: collaborator,
        ),
      );
    },
  );
}

class _PayrollSheet extends StatelessWidget {
  const _PayrollSheet({required this.controller, required this.collaborator});

  final UsersController controller;
  final CollaboratorModel collaborator;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Obx(() {
        final payrolls =
            controller.payrollByUser[collaborator.id] ?? const <PayrollModel>[];
        final isLoading = controller.payrollLoading.contains(collaborator.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Holerites de ${collaborator.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            if (payrolls.isEmpty && !isLoading)
              const Expanded(
                child: Center(
                  child: Text(
                    'Nenhum holerite encontrado.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: payrolls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payroll = payrolls[index];
                    return _PayrollTile(payroll: payroll);
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _PayrollTile extends StatelessWidget {
  const _PayrollTile({required this.payroll});

  final PayrollModel payroll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate =
        payroll.dueDate != null
            ? _dateFormatter.format(payroll.dueDate!)
            : 'Sem prazo';
    final paidAt =
        payroll.paidAt != null
            ? _dateTimeFormatter.format(payroll.paidAt!)
            : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(payroll.reference, style: theme.textTheme.titleMedium),
                const Spacer(),
                Chip(
                  label: Text(_payrollStatusLabel(payroll.status)),
                  backgroundColor: _payrollStatusColor(
                    payroll.status,
                    theme,
                  ).withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _payrollStatusColor(payroll.status, theme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(payroll.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vencimento: $dueDate',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            if (paidAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pago em: $paidAt',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
            if (payroll.paymentMethod != null) ...[
              const SizedBox(height: 4),
              Text(
                'MÃ©todo: ${_paymentMethodLabel(payroll.paymentMethod!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
            if (payroll.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                payroll.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmCollaboratorDeletion(
  BuildContext context,
  UsersController controller,
  CollaboratorModel collaborator,
) async {
  final shouldDelete =
      await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              backgroundColor: context.themeSurface,
              title: const Text('Remover colaborador'),
              content: Text(
                'Tem certeza que deseja remover ${collaborator.name}? '
                'O acesso SerÃ¡ revogado e o registro ficarÃ¡ inativo.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Remover'),
                ),
              ],
            ),
      ) ??
      false;

  if (shouldDelete) {
    await controller.deleteCollaborator(collaborator.id);
  }
}

bool _samePermissions(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final setA = a.toSet();
  final setB = b.toSet();
  return setA.length == setB.length && setA.containsAll(setB);
}

String _moduleLabel(String module) {
  switch (module.toLowerCase()) {
    case 'orders':
      return 'Ordens de serviço';
    case 'inventory':
      return 'Estoque';
    case 'fleet':
      return 'Frota';
    case 'finance':
      return 'Financeiro';
    case 'users':
      return 'Colaboradores';
    case 'purchases':
      return 'Compras';
    default:
      return module.capitalizeFirst ?? module;
  }
}

bool _matchesQuery(
  CollaboratorModel collaborator,
  String query,
  Map<String, String> permissionLabels,
) {
  final lower = query.toLowerCase();
  if (collaborator.name.toLowerCase().contains(lower)) return true;
  if (collaborator.email.toLowerCase().contains(lower)) return true;
  if (_roleLabel(collaborator.role).toLowerCase().contains(lower)) return true;
  for (final code in collaborator.permissions) {
    if (code.toLowerCase().contains(lower)) return true;
    final label = permissionLabels[code];
    if (label != null && label.toLowerCase().contains(lower)) return true;
  }
  return false;
}

String _roleLabel(CollaboratorRole role) {
  switch (role) {
    case CollaboratorRole.admin:
      return 'Administrador';
    case CollaboratorRole.manager:
      return 'Gestor';
    case CollaboratorRole.tech:
      return 'TÃ©cnico';
    case CollaboratorRole.viewer:
      return 'VisualizaÃ§Ã£o';
  }
}

Color _roleColor(CollaboratorRole role, ThemeData theme) {
  switch (role) {
    case CollaboratorRole.admin:
      return theme.colorScheme.primary;
    case CollaboratorRole.manager:
      return Colors.orangeAccent;
    case CollaboratorRole.tech:
      return Colors.lightBlueAccent;
    case CollaboratorRole.viewer:
      return Colors.purpleAccent;
  }
}

String _paymentFrequencyLabel(PaymentFrequency frequency) {
  switch (frequency) {
    case PaymentFrequency.monthly:
      return 'Mensal';
    case PaymentFrequency.biweekly:
      return 'Quinzenal';
    case PaymentFrequency.weekly:
      return 'Semanal';
  }
}

String _paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.pix:
      return 'PIX';
    case PaymentMethod.cash:
      return 'Dinheiro';
    case PaymentMethod.card:
      return 'CartÃ£o';
    case PaymentMethod.bankTransfer:
      return 'TransferÃªncia bancÃ¡ria';
  }
}

String _payrollStatusLabel(PayrollStatus status) {
  switch (status) {
    case PayrollStatus.pending:
      return 'Pendente';
    case PayrollStatus.paid:
      return 'Pago';
  }
}

Color _payrollStatusColor(PayrollStatus status, ThemeData theme) {
  switch (status) {
    case PayrollStatus.pending:
      return Colors.amberAccent;
    case PayrollStatus.paid:
      return theme.colorScheme.secondary;
  }
}
