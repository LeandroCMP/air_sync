import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ignore_for_file: use_build_context_synchronously
import 'users_controller.dart';

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
            hintText: 'Buscar por nome, e-mail ou permissão',
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
                child: const Text('Todos os papÃƒÂ©is'),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (filtered.isEmpty) {
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

                  return _CollaboratorCard(
                    collaborator: collaborator,
                    permissionLabels: labelByPermission,
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
        });
      },
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

    final chips =
        collaborator.permissions
            .map(
              (code) => Chip(
                label: Text(permissionLabels[code] ?? code),
                backgroundColor: context.themeSurface,
              ),
            )
            .toList();

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
                    label: 'SalÃƒÂ¡rio',
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
                    value: 'Dia $paymentDay',
                  ),
                if (compensation?.paymentFrequency != null)
                  _InfoTile(
                    icon: Icons.event_repeat,
                    label: 'FrequÃƒÂªncia',
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
            const SizedBox(height: 12),
            if (chips.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PermissÃƒÂµes (${chips.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              )
            else
              Text(
                'PermissÃƒÂµes determinadas pelo papel.',
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
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
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
                      isPayrollLoading
                          ? 'Carregando...'
                          : 'Holerites ($payrollCount)',
                    ),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
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

class CollaboratorFormController extends GetxController {
  CollaboratorFormController({
    required this.usersController,
    this.collaborator,
  });

  final UsersController usersController;
  final CollaboratorModel? collaborator;

  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController passwordCtrl;
  late final TextEditingController salaryCtrl;
  late final TextEditingController paymentDayCtrl;
  late final TextEditingController hourlyCostCtrl;
  late final TextEditingController notesCtrl;

  final role = CollaboratorRole.tech.obs;
  final active = true.obs;
  final paymentFrequency = Rxn<PaymentFrequency>();
  final paymentMethod = Rxn<PaymentMethod>();
  final useCustomPermissions = false.obs;
  final obscurePassword = true.obs;
  final RxList<String> selectedPermissions = <String>[].obs;

  bool get isEditing => collaborator != null;

  @override
  void onInit() {
    super.onInit();
    role.value = collaborator?.role ?? CollaboratorRole.tech;
    active.value = collaborator?.active ?? true;
    paymentFrequency.value = collaborator?.compensation?.paymentFrequency;
    paymentMethod.value = collaborator?.compensation?.paymentMethod;

    nameCtrl = TextEditingController(text: collaborator?.name ?? '');
    emailCtrl = TextEditingController(text: collaborator?.email ?? '');
    passwordCtrl = TextEditingController();
    salaryCtrl = TextEditingController(
      text:
          collaborator?.compensation?.salary != null
              ? _currencyFormatter.format(collaborator!.compensation!.salary)
              : '',
    );
    paymentDayCtrl = TextEditingController(
      text: collaborator?.compensation?.paymentDay?.toString() ?? '',
    );
    hourlyCostCtrl = TextEditingController(
      text:
          collaborator?.hourlyCost != null
              ? _currencyFormatter.format(collaborator!.hourlyCost)
              : '',
    );
    notesCtrl = TextEditingController(
      text: collaborator?.compensation?.notes ?? '',
    );

    final defaultPermissions = usersController.defaultPermissionsForRole(
      role.value,
    );
    final currentPermissions = collaborator?.permissions ?? defaultPermissions;
    selectedPermissions.assignAll(currentPermissions);
    if (collaborator == null) {
      useCustomPermissions.value = false;
      selectedPermissions.assignAll(defaultPermissions);
    } else {
      final preset = usersController.defaultPermissionsForRole(
        collaborator!.role,
      );
      useCustomPermissions.value =
          !_samePermissions(preset, collaborator!.permissions);
      if (!useCustomPermissions.value) {
        selectedPermissions.assignAll(preset);
      }
    }

    if (role.value == CollaboratorRole.admin) {
      active.value = true;
    }
  }

  static bool _samePermissions(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  void updateRole(CollaboratorRole value) {
    role.value = value;
    if (!useCustomPermissions.value) {
      selectedPermissions.assignAll(
        usersController.defaultPermissionsForRole(value),
      );
    }
    if (value == CollaboratorRole.admin) {
      active.value = true;
    }
  }

  void toggleActive(bool value) {
    if (role.value == CollaboratorRole.admin && !value) {
      usersController.message(
        MessageModel.error(
          title: 'OperaÃƒÂ§ÃƒÂ£o invÃƒÂ¡lida',
          message: 'Administradores nÃƒÂ£o podem ser inativados.',
        ),
      );
      return;
    }
    active.value = value;
  }

  void toggleUseCustomPermissions(bool value) {
    useCustomPermissions.value = value;
    if (!value) {
      selectedPermissions.assignAll(
        usersController.defaultPermissionsForRole(role.value),
      );
    }
  }

  void onPermissionToggle(String code, bool enabled) {
    if (enabled) {
      if (!selectedPermissions.contains(code)) {
        selectedPermissions.add(code);
      }
    } else {
      selectedPermissions.remove(code);
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void updatePaymentFrequency(PaymentFrequency? value) {
    paymentFrequency.value = value;
  }

  void updatePaymentMethod(PaymentMethod? value) {
    paymentMethod.value = value;
  }

  Future<void> submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();

    final salary = _parseCurrency(salaryCtrl.text);
    final hourlyCost = _parseCurrency(hourlyCostCtrl.text);
    final paymentDay =
        paymentDayCtrl.text.trim().isEmpty
            ? null
            : int.parse(paymentDayCtrl.text);
    final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
    final permissions =
        useCustomPermissions.value ? selectedPermissions.toList() : null;
    final bool resolvedActive =
        role.value == CollaboratorRole.admin ? true : active.value;

    if (collaborator == null) {
      final success = await usersController.createCollaborator(
        CollaboratorCreateInput(
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
          role: role.value,
          permissions: permissions,
          salary: salary,
          paymentDay: paymentDay,
          paymentFrequency: paymentFrequency.value,
          paymentMethod: paymentMethod.value,
          hourlyCost: hourlyCost,
          active: resolvedActive,
          compensationNotes: notes,
        ),
      );
      if (success) Navigator.of(context).pop();
      return;
    }

    final success = await usersController.updateCollaborator(
      collaborator!.id,
      CollaboratorUpdateInput(
        name: nameCtrl.text.trim(),
        role: role.value,
        permissions: permissions,
        salary: salary,
        paymentDay: paymentDay,
        paymentFrequency: paymentFrequency.value,
        paymentMethod: paymentMethod.value,
        compensationNotes: notes,
        hourlyCost: hourlyCost,
        active: resolvedActive,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    salaryCtrl.dispose();
    paymentDayCtrl.dispose();
    hourlyCostCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}

class _CollaboratorForm extends StatelessWidget {
  const _CollaboratorForm({
    required this.formController,
    required this.sheetContext,
  });

  final CollaboratorFormController formController;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    final usersController = formController.usersController;
    final theme = Theme.of(context);

    return Obx(() {
      final isEditing = formController.isEditing;
      final loading = usersController.isLoading.value;
      final role = formController.role.value;
      final active = formController.active.value;
      final frequency = formController.paymentFrequency.value;
      final method = formController.paymentMethod.value;
      final useCustom = formController.useCustomPermissions.value;
      final obscurePassword = formController.obscurePassword.value;

      return Form(
        key: formController.formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Editar colaborador' : 'Novo colaborador',
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
                        loading ? null : () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              if (loading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: formController.nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome completo*'),
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do colaborador';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail*'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o e-mail';
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return 'Informe um e-mail vÃƒÂ¡lido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CollaboratorRole>(
                value: role,
                decoration: const InputDecoration(labelText: 'Papel*'),
                dropdownColor: context.themeSurface,
                style: const TextStyle(color: Colors.white),
                items:
                    CollaboratorRole.values
                        .map(
                          (item) => DropdownMenuItem<CollaboratorRole>(
                            value: item,
                            child: Text(_roleLabel(item)),
                          ),
                        )
                        .toList(),
                onChanged:
                    loading
                        ? null
                        : (value) {
                          if (value != null) {
                            formController.updateRole(value);
                          }
                        },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: active,
                onChanged: loading ? null : formController.toggleActive,
                title: const Text(
                  'Ativo',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              if (!isEditing) ...[
                TextFormField(
                  controller: formController.passwordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Senha inicial*',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed:
                          loading
                              ? null
                              : formController.togglePasswordVisibility,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: obscurePassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe uma senha temporÃƒÂ¡ria';
                    }
                    if (value.trim().length < 8) {
                      return 'A senha deve ter ao menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'CompensaÃƒÂ§ÃƒÂ£o',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.salaryCtrl,
                decoration: const InputDecoration(labelText: 'SalÃƒÂ¡rio (R\$)'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.hourlyCostCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custo por hora (R\$)',
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.paymentDayCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dia do pagamento (1-31)',
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final day = int.tryParse(value.trim());
                  if (day == null || day < 1 || day > 31) {
                    return 'Informe um dia entre 1 e 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentFrequency>(
                value: frequency,
                decoration: const InputDecoration(
                  labelText: 'FrequÃƒÂªncia de pagamento',
                ),
                dropdownColor: context.themeSurface,
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem<PaymentFrequency>(
                    value: null,
                    child: Text('Selecionar...'),
                  ),
                  ...PaymentFrequency.values.map(
                    (item) => DropdownMenuItem<PaymentFrequency>(
                      value: item,
                      child: Text(_paymentFrequencyLabel(item)),
                    ),
                  ),
                ],
                onChanged:
                    loading ? null : formController.updatePaymentFrequency,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                value: method,
                decoration: const InputDecoration(
                  labelText: 'Forma de pagamento',
                ),
                dropdownColor: context.themeSurface,
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem<PaymentMethod>(
                    value: null,
                    child: Text('Selecionar...'),
                  ),
                  ...PaymentMethod.values.map(
                    (item) => DropdownMenuItem<PaymentMethod>(
                      value: item,
                      child: Text(_paymentMethodLabel(item)),
                    ),
                  ),
                ],
                onChanged: loading ? null : formController.updatePaymentMethod,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ObservaÃƒÂ§ÃƒÂµes de pagamento',
                ),
                style: const TextStyle(color: Colors.white),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'PermissÃƒÂµes de acesso',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: useCustom,
                onChanged:
                    loading ? null : formController.toggleUseCustomPermissions,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Editar permissÃƒÂµes manualmente',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  useCustom
                      ? 'Selecione as permissÃƒÂµes abaixo.'
                      : 'SerÃƒÂ¡ aplicado o preset do papel escolhido.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              if (useCustom)
                _PermissionSelector(
                  formController: formController,
                  enabled: !loading,
                ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        loading ? null : () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        loading
                            ? null
                            : () => formController.submit(sheetContext),
                    icon: const Icon(Icons.check),
                    label: Text(
                      isEditing ? 'Salvar alteraÃƒÂ§ÃƒÂµes' : 'Cadastrar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.formController,
    required this.enabled,
  });

  final CollaboratorFormController formController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final usersController = formController.usersController;
    return Obx(() {
      if (usersController.isLoadingPermissions.value &&
          usersController.permissions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (usersController.permissions.isEmpty) {
        return const Text(
          'Nenhuma permissÃƒÂ£o disponÃƒÂ­vel para seleÃƒÂ§ÃƒÂ£o.',
          style: TextStyle(color: Colors.white70),
        );
      }

      final grouped = <String, List<PermissionCatalogEntry>>{};
      for (final permission in usersController.permissions) {
        final module = permission.module ?? 'outros';
        grouped
            .putIfAbsent(module, () => <PermissionCatalogEntry>[])
            .add(permission);
      }

      final entries =
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            entries.map((entry) {
              final permissions =
                  entry.value..sort((a, b) => a.label.compareTo(b.label));
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _moduleLabel(entry.key),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          permissions
                              .map(
                                (perm) => FilterChip(
                                  selected: formController.selectedPermissions
                                      .contains(perm.code),
                                  label: Text(perm.label),
                                  onSelected:
                                      enabled
                                          ? (value) =>
                                              formController.onPermissionToggle(
                                                perm.code,
                                                value,
                                              )
                                          : null,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    });
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
        child: _CollaboratorForm(
          formController: formController,
          sheetContext: sheetContext,
        ),
      );
    },
  );
  Future.delayed(const Duration(milliseconds: 200), () {
    if (Get.isRegistered<CollaboratorFormController>(tag: tag)) {
      Get.delete<CollaboratorFormController>(tag: tag, force: true);
    }
  });
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
                'MÃƒÂ©todo: ${_paymentMethodLabel(payroll.paymentMethod!)}',
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
                'O acesso SerÃƒÂ¡ revogado e o registro ficarÃƒÂ¡ inativo.',
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
      return 'TÃƒÂ©cnico';
    case CollaboratorRole.viewer:
      return 'VisualizaÃƒÂ§ÃƒÂ£o';
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
      return 'CartÃƒÂ£o';
    case PaymentMethod.bankTransfer:
      return 'TransferÃƒÂªncia bancÃƒÂ¡ria';
  }
}

String _moduleLabel(String module) {
  switch (module) {
    case 'orders':
      return 'Ordens de serviÃƒÂ§o';
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

double? _parseCurrency(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.parse(digits) / 100;
}

