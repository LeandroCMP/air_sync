import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/inventory_category_model.dart';
import 'package:air_sync/modules/inventory_categories/inventory_categories_controller.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class InventoryCategoriesPage extends StatelessWidget {
  const InventoryCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryCategoriesController>(
      init: InventoryCategoriesController(
        service: Get.find<InventoryService>(),
      ),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorias de estoque'),
            actions: [
              IconButton(
                tooltip: 'Recarregar',
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: context.themeGreen,
            onPressed: () => _openCategoryForm(context, controller),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SafeArea(
            child: Obx(() {
              final isLoading = controller.isLoading.value;
              final items = controller.categories.toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      onChanged: controller.onSearchChanged,
                      decoration: const InputDecoration(
                        labelText: 'Buscar categoria',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  if (isLoading) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.load,
                      child:
                          items.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    child: _EmptyCategoriesState(),
                                  ),
                                ],
                              )
                              : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  120,
                                ),
                                itemBuilder: (_, index) {
                                  final category = items[index];
                                  return _CategoryCard(
                                    category: category,
                                    onEdit:
                                        () => _openCategoryForm(
                                          context,
                                          controller,
                                          category: category,
                                        ),
                                    onDelete:
                                        () => _confirmDeleteCategory(
                                          context,
                                          controller,
                                          category,
                                        ),
                                  );
                                },
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 12),
                                itemCount: items.length,
                              ),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Excluir',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Markup padrão: ${category.markupPercent.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70),
          ),
          if ((category.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              category.description!,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Atualizado em: ${_formatDate(category.updatedAt ?? category.createdAt)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.label_outline, size: 72, color: Colors.white54),
        SizedBox(height: 16),
        Text(
          'Nenhuma categoria cadastrada',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Crie categorias para padronizar o markup dos itens.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

Future<void> _openCategoryForm(
  BuildContext context,
  InventoryCategoriesController controller, {
  InventoryCategoryModel? category,
}) async {
  final nameController = TextEditingController(text: category?.name ?? '');
  final markupController = TextEditingController(
    text:
        category?.markupPercent != null
            ? category!.markupPercent
                .toStringAsFixed(
                  category.markupPercent.roundToDouble() ==
                          category.markupPercent
                      ? 0
                      : 2,
                )
                .replaceAll('.', ',')
            : '',
  );
  final descriptionController = TextEditingController(
    text: category?.description ?? '',
  );
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
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
          top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category == null ? 'Nova categoria' : 'Editar categoria',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: markupController,
                validator: (value) {
                  final normalized = value?.replaceAll(',', '.').trim() ?? '';
                  final parsed = double.tryParse(normalized);
                  if (parsed == null) {
                    return 'Informe o markup';
                  }
                  if (parsed < 0) return 'Valor precisa ser positivo';
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Markup (%)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final markup = double.parse(
                    markupController.text.replaceAll(',', '.'),
                  );
                  final success = await controller.saveCategory(
                    original: category,
                    name: nameController.text.trim(),
                    markupPercent: markup,
                    description:
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                  );
                  if (!sheetCtx.mounted) return;
                  if (success && Navigator.of(sheetCtx).canPop()) {
                    Navigator.of(sheetCtx).pop();
                  }
                },
                child: Text(
                  category == null ? 'Cadastrar' : 'Salvar alterações',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  nameController.dispose();
  markupController.dispose();
  descriptionController.dispose();
}

Future<void> _confirmDeleteCategory(
  BuildContext context,
  InventoryCategoriesController controller,
  InventoryCategoryModel category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (_) => AlertDialog(
          backgroundColor: context.themeSurface,
          title: const Text(
            'Excluir categoria',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tem certeza que deseja remover "${category.name}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
  );

  if (confirmed == true) {
    await controller.deleteCategory(category.id);
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '--';
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
