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
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Colaboradores',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: canCreate
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
      body: SafeArea(
        child: _CollaboratorContent(
          controller: controller,
          canCreate: canCreate,
        ),
      ),
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

            hintText: 'Buscar por nome, e-mail ou permisso',

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

      final label = current == null ? 'Todos os papeis' : _roleLabel(current);

      return PopupMenuButton<CollaboratorRole?>(

        tooltip: 'Filtrar por papel',

        color: context.themeSurface,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        onSelected: controller.applyRoleFilter,

        itemBuilder:

            (context) => [

              CheckedPopupMenuItem<CollaboratorRole?>(

                value: null,

                checked: current == null,

                child: const Text('Todos os papeis'),

              ),

              ...CollaboratorRole.values.map(

                (role) => CheckedPopupMenuItem<CollaboratorRole?>(

                  value: role,

                  checked: current == role,

                  child: Text(_roleLabel(role)),

                ),

              ),

            ],

        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          decoration: BoxDecoration(

            color: context.themeSurface,

            borderRadius: BorderRadius.circular(30),

            border: Border.all(color: context.themeBorder),

          ),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Icon(Icons.filter_alt, color: Colors.white70, size: 18),

              const SizedBox(width: 8),

              Text(label, style: const TextStyle(color: Colors.white)),

              const SizedBox(width: 4),

              const Icon(Icons.keyboard_arrow_down, color: Colors.white54),

            ],

          ),

        ),

      );

    });

  }

}



class _CollaboratorContent extends StatelessWidget {

  const _CollaboratorContent({

    required this.controller,

    required this.canCreate,

  });



  final UsersController controller;

  final bool canCreate;



  @override

  Widget build(BuildContext context) {

    return ValueListenableBuilder<TextEditingValue>(

      valueListenable: controller.searchCtrl,

      builder: (_, value, __) {

        final query = value.text.trim().toLowerCase();

        return Obx(() {

          final isLoading = controller.isLoading.value;

          final items = controller.collaborators.toList();

          final roleFilter = controller.filterRole.value;

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

          final summaryEntries = _buildCollaboratorSummaryEntries(items);

          final hasAny = items.isNotEmpty;

          final hasSearch = query.isNotEmpty;

          final hasFiltersApplied = hasSearch || roleFilter != null;



          return Column(

            children: [

              Padding(

                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

                child: Row(

                  children: [

                    Expanded(child: _UsersSearchField(controller: controller)),

                    const SizedBox(width: 12),

                    _RoleFilterButton(controller: controller),

                  ],

                ),

              ),

              if (isLoading) const LinearProgressIndicator(minHeight: 2),

              Expanded(

                child: RefreshIndicator(

                  color: context.themePrimary,

                  backgroundColor: context.themeSurface,

                  onRefresh: controller.loadCollaborators,

                  child: CustomScrollView(

                    physics: const BouncingScrollPhysics(

                      parent: AlwaysScrollableScrollPhysics(),

                    ),

                    slivers: [

                      if (summaryEntries.isNotEmpty)

                        SliverToBoxAdapter(

                          child: Padding(

                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                            child: _CollaboratorSummaryRow(

                              entries: summaryEntries,

                              selectedRole: roleFilter,

                              onSelect: controller.applyRoleFilter,

                            ),

                          ),

                        ),

                      if (filtered.isNotEmpty)

                        SliverList(

                          delegate: SliverChildBuilderDelegate((

                            context,

                            index,

                          ) {

                            final collaborator = filtered[index];

                            final moduleCounts = <String, int>{};

                            for (final code in collaborator.permissions) {

                              final module =

                                  catalogByCode[code]?.module?.toLowerCase() ??

                                  'outros';

                              moduleCounts[module] =

                                  (moduleCounts[module] ?? 0) + 1;

                            }

                            final defaultPermissions = controller

                                .defaultPermissionsForRole(collaborator.role);

                            final usesCustomPermissions =

                                !_samePermissions(

                                  defaultPermissions,

                                  collaborator.permissions,

                                );



                            return Padding(

                              padding: EdgeInsets.fromLTRB(

                                16,

                                0,

                                16,

                                index == filtered.length - 1 ? 120 : 16,

                              ),

                              child: Obx(() {

                                final payrollList =

                                    controller.payrollByUser[collaborator.id] ??

                                    const <PayrollModel>[];

                                final isPayrollLoading = controller

                                    .payrollLoading

                                    .contains(collaborator.id);

                                final isDeleting = controller.deletingIds

                                    .contains(collaborator.id);

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

                              }),

                            );

                          }, childCount: filtered.length),

                        )

                      else

                        SliverFillRemaining(

                          hasScrollBody: false,

                          child: _CollaboratorEmptyState(

                            hasAnyCollaborators: hasAny,

                            hasSearch: hasSearch,

                            filterRole: roleFilter,

                            canCreate: canCreate,

                            onClearFilters:

                                hasFiltersApplied

                                    ? () {

                                      if (hasSearch) {

                                        controller.searchCtrl.clear();

                                      }

                                      if (roleFilter != null) {

                                        controller.applyRoleFilter(null);

                                      }

                                    }

                                    : null,

                            onCreate:

                                canCreate

                                    ? () => _openCollaboratorForm(

                                      context,

                                      controller,

                                    )

                                    : null,

                          ),

                        ),

                    ],

                  ),

                ),

              ),

            ],

          );

        });

      },

    );

  }

}



class _CollaboratorEmptyState extends StatelessWidget {

  const _CollaboratorEmptyState({

    required this.hasAnyCollaborators,

    required this.hasSearch,

    required this.filterRole,

    required this.canCreate,

    this.onClearFilters,

    this.onCreate,

  });



  final bool hasAnyCollaborators;

  final bool hasSearch;

  final CollaboratorRole? filterRole;

  final bool canCreate;

  final VoidCallback? onClearFilters;

  final VoidCallback? onCreate;



  @override

  Widget build(BuildContext context) {

    final message =

        hasAnyCollaborators

            ? hasSearch

                ? 'Nenhum colaborador encontrado para sua busca.'

                : filterRole != null

                ? 'Nenhum colaborador com o papel selecionado.'

                : 'Nenhum colaborador disponvel.'

            : 'Nenhum colaborador cadastrado ainda.';

    final subtitle =

        hasAnyCollaborators

            ? 'Ajuste a busca ou os filtros para visualizar outros resultados.'

            : 'Use o boto abaixo para cadastrar seu primeiro colaborador.';



    return Center(

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 32),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(Icons.badge_outlined, size: 72, color: Colors.white38),

            const SizedBox(height: 16),

            Text(

              message,

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

            const SizedBox(height: 20),

            if (onClearFilters != null)

              OutlinedButton.icon(

                onPressed: onClearFilters,

                icon: const Icon(Icons.filter_alt_off, color: Colors.white70),

                label: const Text('Limpar filtros'),

              ),

            if (canCreate && onCreate != null) ...[

              const SizedBox(height: 12),

              FilledButton.icon(

                style: FilledButton.styleFrom(

                  backgroundColor: context.themeGreen,

                ),

                onPressed: onCreate,

                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),

                label: const Text(

                  'Cadastrar colaborador',

                  style: TextStyle(color: Colors.white),

                ),

              ),

            ],

          ],

        ),

      ),

    );

  }

}



class _CollaboratorSummaryRow extends StatelessWidget {

  const _CollaboratorSummaryRow({

    required this.entries,

    required this.selectedRole,

    required this.onSelect,

  });



  final List<_CollaboratorSummaryInfo> entries;

  final CollaboratorRole? selectedRole;

  final Future<void> Function(CollaboratorRole?) onSelect;



  @override

  Widget build(BuildContext context) {

    if (entries.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(

        children:

            entries.map((info) {

              final bool isSelected =

                  info.role == null

                      ? selectedRole == null

                      : selectedRole == info.role;

              return Padding(

                padding: const EdgeInsets.only(right: 12),

                child: GestureDetector(

                  onTap: () {

                    final CollaboratorRole? target =

                        info.role == null || isSelected ? null : info.role;

                    onSelect(target);

                  },

                  child: AnimatedContainer(

                    duration: const Duration(milliseconds: 200),

                    padding: const EdgeInsets.all(14),

                    width: 150,

                    height: 120,

                    decoration: BoxDecoration(

                      color:

                          isSelected

                              ? info.color.withValues(alpha: 0.18)

                              : context.themeSurface,

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(

                        color: isSelected ? info.color : context.themeBorder,

                      ),

                    ),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Icon(info.icon, color: info.color, size: 16),

                        const Spacer(),

                        Text(

                          info.value,

                          style: const TextStyle(

                            color: Colors.white,

                            fontSize: 18,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height: 2),

                        Text(

                          info.label,

                          style: const TextStyle(

                            color: Colors.white70,

                            fontSize: 12,

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              );

            }).toList(),

      ),

    );

  }

}



class _CollaboratorSummaryInfo {

  const _CollaboratorSummaryInfo({

    required this.role,

    required this.label,

    required this.value,

    required this.icon,

    required this.color,

  });



  final CollaboratorRole? role;

  final String label;

  final String value;

  final IconData icon;

  final Color color;

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

              (entry) => Container(

                padding: const EdgeInsets.symmetric(

                  horizontal: 10,

                  vertical: 6,

                ),

                decoration: BoxDecoration(

                  color: Colors.white.withValues(alpha: 0.08),

                  borderRadius: BorderRadius.circular(20),

                ),

                child: Text(

                  '${_moduleLabel(entry.key)} (${entry.value})',

                  style: const TextStyle(color: Colors.white70, fontSize: 12),

                ),

              ),

            )

            .toList();

    final initials = _initialsFor(collaborator.name);



    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.white12),

        gradient: LinearGradient(

          colors: [

            Color.lerp(context.themeSurface, Colors.white, 0.04)!,

            context.themeSurface,

          ],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              CircleAvatar(

                radius: 26,

                backgroundColor: context.themeGreen.withValues(alpha: 0.2),

                child: Text(

                  initials,

                  style: const TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Wrap(

                      spacing: 8,

                      runSpacing: 8,

                      children: [

                        _PillBadge(

                          icon: Icons.badge,

                          label: _roleLabel(collaborator.role),

                          color: _roleColor(collaborator.role, theme),

                        ),

                        _PillBadge(

                          icon:

                              collaborator.active

                                  ? Icons.check_circle

                                  : Icons.pause_circle_filled,

                          label: collaborator.active ? 'Ativo' : 'Inativo',

                          color:

                              collaborator.active

                                  ? context.themeGreen

                                  : theme.colorScheme.error,

                        ),

                        if (usesCustomPermissions)

                          _PillBadge(

                            icon: Icons.tune,

                            label: 'Personalizadas',

                            color: theme.colorScheme.secondary,

                          ),

                      ],

                    ),

                    const SizedBox(height: 10),

                    Text(

                      collaborator.name,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(

                        color: Colors.white,

                        fontSize: 18,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      collaborator.email,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(color: Colors.white70),

                    ),

                    if (summaryChips.isNotEmpty) ...[

                      const SizedBox(height: 8),

                      Wrap(spacing: 6, runSpacing: 6, children: summaryChips),

                    ],

                  ],

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              if (salary != null)
                _InfoTile(
                  icon: Icons.attach_money,
                  label: 'SalÃ¡rio',
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
                  label: 'FrequÃªncia',
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
              _InfoTile(
                icon: Icons.lock_person,
                label: 'PermissÃµes',
                value: usesCustomPermissions
                    ? 'Personalizadas (${collaborator.permissions.length})'
                    : 'Papel padrÃ£o',
              ),
              if (moduleCounts.isNotEmpty)
                _InfoTile(
                  icon: Icons.tune,
                  label: 'Por mÃ³dulo',
                  value: moduleCounts.entries
                      .map((e) => '${_moduleLabel(e.key)}: ${e.value}')
                      .join('  â€¢  '),
                ),
              if (payrollCount > 0)
                _InfoTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Holerites',
                  value: '$payrollCount',
                ),
            ],
          ),

          if (compensation?.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              compensation!.notes!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],

          if (isDeleting) ...[

            const SizedBox(height: 12),

            Row(

              children: const [

                SizedBox(

                  width: 16,

                  height: 16,

                  child: CircularProgressIndicator(strokeWidth: 2),

                ),

                SizedBox(width: 8),

                Text('Processando...', style: TextStyle(color: Colors.white70)),

              ],

            ),

          ],

          const SizedBox(height: 16),

          Row(

            children: [

              if (showPayrollButton)

                Expanded(

                  child: _CollaboratorActionButton(

                    icon: Icons.receipt_long,

                    label:

                        payrollCount == 0

                            ? 'Ver holerites'

                            : 'Holerites ($payrollCount)',

                    onTap: isPayrollLoading ? null : onPayroll,

                    isBusy: isPayrollLoading,

                  ),

                ),

              if (showPayrollButton && (onEdit != null || onDelete != null))

                const SizedBox(width: 12),

              if (onEdit != null)

                Expanded(

                  child: _CollaboratorActionButton(

                    icon: Icons.edit_outlined,

                    label: 'Editar',

                    onTap: onEdit,

                  ),

                ),

              if (onEdit != null && onDelete != null) const SizedBox(width: 12),

              if (onDelete != null)

                Expanded(

                  child: _CollaboratorActionButton(

                    icon: Icons.delete_outline,

                    label: 'Remover',

                    onTap: isDeleting ? null : onDelete,

                    isDestructive: true,

                  ),

                ),

            ],

          ),

        ],

      ),

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

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(

        color: context.themeSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: context.themeBorder),

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, size: 18, color: Colors.white70),

          const SizedBox(width: 8),

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

      ),

    );

  }

}



class _PillBadge extends StatelessWidget {

  const _PillBadge({

    required this.icon,

    required this.label,

    required this.color,

  });



  final IconData icon;

  final String label;

  final Color color;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.15),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: color.withValues(alpha: 0.4)),

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, color: color, size: 16),

          const SizedBox(width: 6),

          Text(

            label,

            style: TextStyle(color: color, fontWeight: FontWeight.w600),

          ),

        ],

      ),

    );

  }

}



class _CollaboratorActionButton extends StatelessWidget {

  const _CollaboratorActionButton({

    required this.icon,

    required this.label,

    required this.onTap,

    this.isBusy = false,

    this.isDestructive = false,

  });



  final IconData icon;

  final String label;

  final VoidCallback? onTap;

  final bool isBusy;

  final bool isDestructive;



  @override

  Widget build(BuildContext context) {

    final color = isDestructive ? Colors.redAccent : Colors.white;

    return SizedBox(

      height: 44,

      child: TextButton(

        style: TextButton.styleFrom(

          backgroundColor: Colors.white.withValues(alpha: 0.08),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(28),

          ),

        ),

        onPressed: isBusy ? null : onTap,

        child:

            isBusy

                ? const SizedBox(

                  width: 18,

                  height: 18,

                  child: CircularProgressIndicator(strokeWidth: 2),

                )

                : Row(

                  mainAxisSize: MainAxisSize.min,

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Icon(icon, color: color, size: 18),

                    const SizedBox(width: 6),

                    Flexible(

                      child: Text(

                        label,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(color: color),

                      ),

                    ),

                  ],

                ),

      ),

    );

  }

}



String _initialsFor(String name) {

  final parts = name.trim().split(RegExp(r'\s+'));

  final buffer = StringBuffer();

  for (final part in parts) {

    if (part.isEmpty) continue;

    buffer.write(part[0].toUpperCase());

    if (buffer.length == 2) break;

  }

  return buffer.isEmpty ? '?' : buffer.toString();

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

                'Mtodo: ${_paymentMethodLabel(payroll.paymentMethod!)}',

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

                'O acesso Ser revogado e o registro ficar inativo.',

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

      return 'Ordens de servio';

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



List<_CollaboratorSummaryInfo> _buildCollaboratorSummaryEntries(

  List<CollaboratorModel> collaborators,

) {

  if (collaborators.isEmpty) return const [];

  final total = collaborators.length;

  final counts = <CollaboratorRole, int>{};

  for (final role in CollaboratorRole.values) {

    counts[role] = collaborators.where((c) => c.role == role).length;

  }

  return [

    _CollaboratorSummaryInfo(

      role: null,

      label: 'Todos',

      value: total.toString(),

      icon: Icons.people_outline,

      color: const Color(0xFF90CAF9),

    ),

    _CollaboratorSummaryInfo(

      role: CollaboratorRole.owner,

      label: 'Owners',

      value: (counts[CollaboratorRole.owner] ?? 0).toString(),

      icon: Icons.verified,

      color: Colors.redAccent,

    ),

    _CollaboratorSummaryInfo(

      role: CollaboratorRole.admin,

      label: 'Admins',

      value: (counts[CollaboratorRole.admin] ?? 0).toString(),

      icon: Icons.verified_user,

      color: Colors.redAccent,

    ),

    _CollaboratorSummaryInfo(

      role: CollaboratorRole.manager,

      label: 'Gestores',

      value: (counts[CollaboratorRole.manager] ?? 0).toString(),

      icon: Icons.manage_accounts,

      color: Colors.orangeAccent,

    ),

    _CollaboratorSummaryInfo(

      role: CollaboratorRole.tech,

      label: 'Tcnicos',

      value: (counts[CollaboratorRole.tech] ?? 0).toString(),

      icon: Icons.handyman,

      color: Colors.lightBlueAccent,

    ),

    _CollaboratorSummaryInfo(

      role: CollaboratorRole.viewer,

      label: 'Visualizao',

      value: (counts[CollaboratorRole.viewer] ?? 0).toString(),

      icon: Icons.visibility_outlined,

      color: Colors.purpleAccent,

    ),

  ];

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
    case CollaboratorRole.owner:

      return 'Administrador Global (owner)';

    case CollaboratorRole.admin:

      return 'Administrador';

    case CollaboratorRole.manager:

      return 'Gestor';

    case CollaboratorRole.tech:

      return 'Tcnico';

    case CollaboratorRole.viewer:

      return 'Visualizao';

  }

}



Color _roleColor(CollaboratorRole role, ThemeData theme) {

  switch (role) {
    case CollaboratorRole.owner:

      return Colors.redAccent;

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

      return 'Carto';

    case PaymentMethod.bankTransfer:

      return 'Transferncia bancria';

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

