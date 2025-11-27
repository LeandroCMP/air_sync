import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/utils/formatters/upper_case_input_formatter.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'suppliers_controller.dart';

class SuppliersPage extends GetView<SuppliersController> {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Fornecedores',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openCreateBottomSheet(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Obx(() {
          final suppliers = controller.items;
          final loading = controller.isLoading.value;
          final filter = controller.statusFilter.value;
          final filtered = _applySupplierFilter(suppliers, filter);
          final summaryEntries = _buildSupplierSummaryEntries(suppliers);
          final hasAny = suppliers.isNotEmpty;
          final hasFiltered = filtered.isNotEmpty;
          final hasSearch = controller.searchTerm.value.isNotEmpty;

          return Column(
            children: [
              if (loading) const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _SupplierSearchField(controller: controller),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (summaryEntries.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _SupplierSummaryRow(
                              entries: summaryEntries,
                              selectedKey: filter,
                              onSelect: controller.setStatusFilter,
                            ),
                          ),
                        ),
                      if (hasFiltered)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final supplier = filtered[index];
                              final isDeleting = controller.deletingIds
                                  .contains(supplier.id);
                              return Padding(
                                padding:
                                    EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom:
                                          index == filtered.length - 1 ? 24 : 14,
                                    ),
                                child: _SupplierCard(
                                  supplier: supplier,
                                  isDeleting: isDeleting,
                                  onEdit:
                                      () => _openEditBottomSheet(
                                        context,
                                        supplier.id,
                                        supplier.name,
                                        supplier.docNumber,
                                        supplier.phone,
                                        supplier.email,
                                        supplier.notes,
                                      ),
                                  onDelete:
                                      () => _confirmDeletion(context, supplier),
                                ),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        )
                      else
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptySuppliers(
                            hasAnySuppliers: hasAny,
                            hasSearch: hasSearch,
                            activeFilter: filter,
                            onClearFilters: () {
                              if (controller.statusFilter.value != 'all') {
                                controller.setStatusFilter('all');
                              }
                              if (hasSearch) {
                                controller.clearSearch();
                              }
                            },
                            onCreate: () => _openCreateBottomSheet(context),
                          ),
                        ),
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

  Future<void> _confirmDeletion(
    BuildContext context,
    SupplierModel supplier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remover fornecedor'),
            content: Text('Excluir "${supplier.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await controller.delete(supplier.id);
    }
  }

  void _openCreateBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Novo fornecedor',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UpperCaseTextFormatter()],
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: docCtrl,
                          inputFormatters: [CnpjCpfInputFormatter()],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Documento',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          inputFormatters: [PhoneInputFormatter()],
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    validator: FormValidators.validateOptionalEmail,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                      foregroundColor: context.themeGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final success = await controller.create(
                        name: nameCtrl.text.trim().toUpperCase(),
                        docNumber:
                            docCtrl.text.trim().isEmpty
                                ? null
                                : docCtrl.text.trim(),
                        phone:
                            phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                        email:
                            emailCtrl.text.trim().isEmpty
                                ? null
                                : emailCtrl.text.trim(),
                        notes:
                            notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                      );
                      if (success && sheetCtx.mounted) {
                        Navigator.of(sheetCtx, rootNavigator: true).pop();
                      }
                    },
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        () => Navigator.of(sheetCtx, rootNavigator: true).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditBottomSheet(
    BuildContext context,
    String id,
    String name,
    String? doc,
    String? phone,
    String? email,
    String? notes,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: name.toUpperCase());
    final docCtrl = TextEditingController(text: doc ?? '');
    final phoneCtrl = TextEditingController(text: phone ?? '');
    final emailCtrl = TextEditingController(text: email ?? '');
    final notesCtrl = TextEditingController(text: notes ?? '');

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Editar fornecedor',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UpperCaseTextFormatter()],
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: docCtrl,
                          validator: FormValidators.validateOptionalCpfCnpj,
                          inputFormatters: [CnpjCpfInputFormatter()],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Documento',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          inputFormatters: [PhoneInputFormatter()],
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    validator: FormValidators.validateOptionalEmail,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                      foregroundColor: context.themeGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final success = await controller.updateSupplier(id, {
                        'name': nameCtrl.text.trim().toUpperCase(),
                        'docNumber':
                            docCtrl.text.trim().isEmpty
                                ? null
                                : docCtrl.text.trim(),
                        'phone':
                            phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                        'email':
                            emailCtrl.text.trim().isEmpty
                                ? null
                                : emailCtrl.text.trim(),
                        'notes':
                            notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                      });
                      if (success && sheetCtx.mounted) {
                        Navigator.of(sheetCtx, rootNavigator: true).pop();
                      }
                    },
                    child: const Text(
                      'Salvar alterações',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        () => Navigator.of(sheetCtx, rootNavigator: true).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SupplierSearchField extends StatelessWidget {
  const _SupplierSearchField({required this.controller});

  final SuppliersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TextField(
        controller: controller.searchCtrl,
        onChanged: controller.onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: 'Buscar por nome, documento ou contato',
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              controller.searchTerm.value.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearSearch,
                  ),
        ),
      ),
    );
  }
}

class _EmptySuppliers extends StatelessWidget {
  const _EmptySuppliers({
    required this.hasAnySuppliers,
    required this.hasSearch,
    required this.activeFilter,
    required this.onClearFilters,
    required this.onCreate,
  });

  final bool hasAnySuppliers;
  final bool hasSearch;
  final String activeFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    late final String title;
    late final String subtitle;
    var showReset = false;
    var showCreate = true;

    if (!hasAnySuppliers) {
      title = 'Você ainda não cadastrou fornecedores';
      subtitle = 'Use o botão abaixo para adicionar o primeiro parceiro.';
    } else if (hasSearch) {
      title = 'Nenhum fornecedor corresponde à busca';
      subtitle = 'Tente outro termo ou limpe a busca para ver todos.';
      showReset = true;
      showCreate = false;
    } else if (activeFilter != 'all') {
      title = 'Nenhum fornecedor no filtro selecionado';
      subtitle = 'Limpe os filtros para visualizar todos os registros.';
      showReset = true;
      showCreate = false;
    } else {
      title = 'Nenhum fornecedor encontrado';
      subtitle = 'Ajuste os filtros ou cadastre um novo fornecedor.';
      showReset = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 72, color: Colors.white54),
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
          if (showReset)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          if (showReset && showCreate) const SizedBox(height: 12),
          if (showCreate)
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar fornecedor'),
            ),
        ],
      ),
    );
  }
}

List<_SupplierSummaryInfo> _buildSupplierSummaryEntries(
  List<SupplierModel> suppliers,
) {
  final total = suppliers.length;
  final withDoc =
      suppliers.where((s) => (s.docNumber ?? '').trim().isNotEmpty).length;
  final withPhone =
      suppliers.where((s) => (s.phone ?? '').trim().isNotEmpty).length;
  final withEmail =
      suppliers.where((s) => (s.email ?? '').trim().isNotEmpty).length;
  final withNotes =
      suppliers.where((s) => (s.notes ?? '').trim().isNotEmpty).length;

  return [
    _SupplierSummaryInfo(
      key: 'all',
      label: 'Total',
      value: total.toString(),
      color: Colors.blueAccent,
      icon: Icons.people_alt_outlined,
    ),
    _SupplierSummaryInfo(
      key: 'doc',
      label: 'Com documento',
      value: withDoc.toString(),
      color: Colors.tealAccent,
      icon: Icons.badge_outlined,
    ),
    _SupplierSummaryInfo(
      key: 'phone',
      label: 'Com telefone',
      value: withPhone.toString(),
      color: Colors.orangeAccent,
      icon: Icons.phone_in_talk_outlined,
    ),
    _SupplierSummaryInfo(
      key: 'email',
      label: 'Com e-mail',
      value: withEmail.toString(),
      color: Colors.purpleAccent,
      icon: Icons.alternate_email,
    ),
    _SupplierSummaryInfo(
      key: 'notes',
      label: 'Com notas',
      value: withNotes.toString(),
      color: Colors.greenAccent,
      icon: Icons.note_alt_outlined,
    ),
  ];
}

List<SupplierModel> _applySupplierFilter(
  List<SupplierModel> suppliers,
  String filter,
) {
  switch (filter) {
    case 'doc':
      return suppliers
          .where((s) => (s.docNumber ?? '').trim().isNotEmpty)
          .toList();
    case 'phone':
      return suppliers.where((s) => (s.phone ?? '').trim().isNotEmpty).toList();
    case 'email':
      return suppliers.where((s) => (s.email ?? '').trim().isNotEmpty).toList();
    case 'notes':
      return suppliers.where((s) => (s.notes ?? '').trim().isNotEmpty).toList();
    default:
      return suppliers;
  }
}

class _SupplierSummaryRow extends StatelessWidget {
  const _SupplierSummaryRow({
    required this.entries,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<_SupplierSummaryInfo> entries;
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _SupplierSummaryInfo {
  const _SupplierSummaryInfo({
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

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final SupplierModel supplier;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void addChip(IconData icon, String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      chips.add(_InfoChip(icon: icon, text: text));
    }

    addChip(Icons.badge_outlined, supplier.docNumber);
    addChip(Icons.phone, supplier.phone);
    addChip(Icons.email_outlined, supplier.email);

    final notes = (supplier.notes ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chips.isEmpty ? 'Sem contatos cadastrados' : 'Contatos',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: onEdit,
                  ),
                  isDeleting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: onDelete,
                      ),
                ],
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 8, children: chips),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(notes, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
