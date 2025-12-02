import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/modules/cost_centers/cost_centers_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CostCentersPage extends GetView<CostCentersController> {
  const CostCentersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Centros de custo'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.isLoading.value ? null : controller.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCostCenterForm(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Buscar centro de custo',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.themePrimary),
                ),
              ),
              onChanged: (value) => controller.search.value = value,
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLoading = controller.isLoading.value;
              final items = controller.filteredCenters;
              if (isLoading && items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    controller.search.value.trim().isEmpty
                        ? 'Nenhum centro cadastrado ainda.'
                        : 'Nenhum centro encontrado para a busca.',
                    style: TextStyle(color: context.themeTextSubtle),
                  ),
                );
              }
              return RefreshIndicator(
                color: context.themePrimary,
                onRefresh: controller.load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemBuilder: (_, index) {
                    final center = items[index];
                    return _CostCenterTile(
                      center: center,
                      onEdit: () =>
                          _showCostCenterForm(context, controller, center: center),
                      onToggle: () => controller.toggleActive(center),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CostCenterTile extends StatelessWidget {
  const _CostCenterTile({
    required this.center,
    required this.onEdit,
    required this.onToggle,
  });

  final CostCenterModel center;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final subtitleLines = <String>[];
    if ((center.code ?? '').isNotEmpty) {
      subtitleLines.add('Código: ${center.code}');
    }
    if ((center.description ?? '').isNotEmpty) {
      subtitleLines.add(center.description!.trim());
    }
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: context.shadowCard,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                center.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    center.active
                        ? Colors.greenAccent.withValues(alpha: .18)
                        : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                center.active ? 'Ativo' : 'Inativo',
                style: TextStyle(
                  color: center.active ? Colors.greenAccent : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle:
            subtitleLines.isEmpty
                ? null
                : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    subtitleLines.join('\n'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
        trailing: PopupMenuButton<String>(
          color: context.themeSurface,
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Editar'),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Text(center.active ? 'Desativar' : 'Ativar'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'toggle') {
              onToggle();
            }
          },
        ),
      ),
    );
  }
}

Future<void> _showCostCenterForm(
  BuildContext context,
  CostCentersController controller, {
  CostCenterModel? center,
}) async {
  final nameCtrl = TextEditingController(text: center?.name ?? '');
  final codeCtrl = TextEditingController(text: center?.code ?? '');
  final descriptionCtrl =
      TextEditingController(text: center?.description ?? '');
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
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                center == null ? 'Novo centro de custo' : 'Editar centro de custo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Informe o nome'
                            : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: codeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Código (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionCtrl,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await controller.save(
                      id: center?.id,
                      name: nameCtrl.text,
                      code: codeCtrl.text,
                      description: descriptionCtrl.text,
                    );
                    if (sheetCtx.mounted) {
                      Navigator.of(sheetCtx).pop();
                    }
                  },
                  child: Text(
                    center == null ? 'Cadastrar' : 'Salvar alterações',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  nameCtrl.dispose();
  codeCtrl.dispose();
  descriptionCtrl.dispose();
}
