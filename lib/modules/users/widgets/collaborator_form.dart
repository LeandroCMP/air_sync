import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../users_controller.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

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
  final obscurePassword = true.obs;
  final useCustomPermissions = false.obs;
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

    if (_isAdminLike(role.value)) {
      active.value = true;
    }
  }

  static bool _samePermissions(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void updateRole(CollaboratorRole value) {
    role.value = value;
    if (!useCustomPermissions.value) {
      selectedPermissions.assignAll(
        usersController.defaultPermissionsForRole(value),
      );
    }
    if (_isAdminLike(value)) {
      active.value = true;
    }
  }

  void toggleActive(bool value) {
    if (_isAdminLike(role.value) && !value) {
      usersController.message(
        MessageModel.error(
          title: 'Operação inválida',
          message: 'Administradores não podem ser inativados.',
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

  void togglePermission(String code, bool enabled) {
    if (enabled) {
      if (!selectedPermissions.contains(code)) {
        selectedPermissions.add(code);
      }
    } else {
      selectedPermissions.remove(code);
    }
  }

  Future<void> submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
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
    final resolvedActive =
        _isAdminLike(role.value) ? true : active.value;

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
      if (!context.mounted) return;
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
    if (!context.mounted) return;
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

bool _isAdminLike(CollaboratorRole role) =>
    role == CollaboratorRole.admin || role == CollaboratorRole.owner;

class CollaboratorForm extends StatelessWidget {
  const CollaboratorForm({
    super.key,
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
                    return 'Informe um e-mail válido';
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
                value: _isAdminLike(role) ? true : active,
                onChanged:
                    loading || _isAdminLike(role)
                        ? null
                        : formController.toggleActive,
                title: const Text(
                  'Ativo',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle:
                    _isAdminLike(role)
                        ? const Text(
                          'Administradores permanecem ativos',
                          style: TextStyle(color: Colors.white60),
                        )
                        : null,
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
                      return 'Informe uma senha temporária';
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
                'Compensação',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.salaryCtrl,
                decoration: const InputDecoration(labelText: 'Salário (R\$)'),
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
                  labelText: 'Frequência de pagamento',
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
                    loading
                        ? null
                        : (value) =>
                            formController.paymentFrequency.value = value,
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
                onChanged:
                    loading
                        ? null
                        : (value) => formController.paymentMethod.value = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: formController.notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações de pagamento',
                ),
                style: const TextStyle(color: Colors.white),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Text(
                'Permissões de acesso',
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
                  'Editar permissões manualmente',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  useCustom
                      ? 'Selecione as permissões abaixo.'
                      : 'Será aplicado o preset do papel escolhido.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              if (useCustom)
                _PermissionSelector(
                  formController: formController,
                  enabled: !loading,
                )
              else
                const _PermissionsInfoCard(),
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
                    label: Text(isEditing ? 'Salvar alterações' : 'Cadastrar'),
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

class _PermissionSelector extends StatefulWidget {
  const _PermissionSelector({
    required this.formController,
    required this.enabled,
  });

  final CollaboratorFormController formController;
  final bool enabled;

  @override
  State<_PermissionSelector> createState() => _PermissionSelectorState();
}

class _PermissionSelectorState extends State<_PermissionSelector> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersController = widget.formController.usersController;
    return Obx(() {
      final isLoading = usersController.isLoadingPermissions.value;
      final catalog = usersController.permissions;

      if (isLoading && catalog.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        );
      }

      if (catalog.isEmpty) {
        return const Text(
          'Nenhuma permissão disponível para seleção.',
          style: TextStyle(color: Colors.white70),
        );
      }

      final grouped = <String, List<PermissionCatalogEntry>>{};
      for (final permission in catalog) {
        final buffer =
            StringBuffer()
              ..write(permission.label)
              ..write(' ')
              ..write(permission.code);
        if (permission.description != null) {
          buffer.write(' ');
          buffer.write(permission.description);
        }
        final haystack = buffer.toString().toLowerCase();
        if (_query.isNotEmpty && !haystack.contains(_query)) {
          continue;
        }
        final module = permission.module ?? 'outros';
        grouped
            .putIfAbsent(module, () => <PermissionCatalogEntry>[])
            .add(permission);
      }

      final entries =
          grouped.entries.toList()..sort(
            (a, b) => _moduleLabel(a.key).compareTo(_moduleLabel(b.key)),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou código da permissão',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon:
                  _query.isEmpty
                      ? null
                      : IconButton(
                        onPressed: _searchCtrl.clear,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
              filled: true,
              fillColor: context.themeSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.themeBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.themeBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.themePrimary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 3,
              color: context.themePrimary,
              backgroundColor: Colors.white24,
            ),
          ],
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'Nenhuma permissão encontrada para o filtro informado.',
              style: TextStyle(color: Colors.white70),
            )
          else
            ...entries.map((entry) {
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
                          permissions.map((perm) {
                            final description = perm.description?.trim();
                            final tooltip =
                                description != null && description.isNotEmpty
                                    ? description
                                    : 'Código: ${perm.code}';
                            final selected = widget
                                .formController
                                .selectedPermissions
                                .contains(perm.code);
                            return Tooltip(
                              message: tooltip,
                              waitDuration: const Duration(milliseconds: 300),
                              child: FilterChip(
                                selected: selected,
                                label: Text(perm.label),
                                onSelected:
                                    widget.enabled
                                        ? (value) => widget.formController
                                            .togglePermission(perm.code, value)
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    });
  }
}

class _PermissionsInfoCard extends StatelessWidget {
  const _PermissionsInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'As permissões deste colaborador seguirão o preset do papel selecionado.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

String _roleLabel(CollaboratorRole role) {
  switch (role) {
    case CollaboratorRole.owner:
      return 'Administrador Global (owner)';
    case CollaboratorRole.admin:
      return 'Administrador';
    case CollaboratorRole.manager:
      return 'Gestor';
    case CollaboratorRole.tech:
      return 'Técnico';
    case CollaboratorRole.viewer:
      return 'Visualização';
  }
}

String _moduleLabel(String module) {
  switch (module) {
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
      return 'Cartão';
    case PaymentMethod.bankTransfer:
      return 'Transferência bancária';
  }
}

double? _parseCurrency(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.parse(digits) / 100;
}
