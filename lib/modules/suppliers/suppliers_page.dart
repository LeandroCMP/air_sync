import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
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
      body: Obx(() {
        final list = controller.items;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (controller.isLoading.value)
                const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              TextField(
                controller: controller.searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar fornecedor',
                ),
                onChanged: (v) => controller.load(text: v.trim()),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty && controller.isLoading.isFalse)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Sem fornecedores',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      final isDeleting = controller.deletingIds.contains(s.id);
                      final sub = [
                        s.docNumber,
                        s.phone,
                        s.email,
                      ].where((e) => (e ?? '').isNotEmpty).join(' - ');
                      return Dismissible(
                        key: ValueKey(s.id),
                        direction:
                            isDeleting
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          if (controller.deletingIds.contains(s.id)) {
                            return false;
                          }
                          final ok = await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Remover fornecedor'),
                                  content: Text('Excluir "${s.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(ctx).pop(true),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                          );
                          if (ok != true) {
                            return false;
                          }
                          return await controller.delete(s.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.themeGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            iconColor: Colors.white70,
                            textColor: Colors.white70,
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text(s.name),
                            subtitle: sub.isEmpty ? null : Text(sub),
                            trailing:
                                isDeleting
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    )
                                    : IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => _openEditBottomSheet(
                                            context,
                                            s.id,
                                            s.name,
                                            s.docNumber,
                                            s.phone,
                                            s.email,
                                            s.notes,
                                          ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
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
      isDismissible: false,
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Novo fornecedor',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          inputFormatters: [PhoneInputFormatter()],
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    validator: FormValidators.validateOptionalEmail,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observacoes',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themeGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        final success = await controller.create(
                          name: nameCtrl.text.trim(),
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
                        if (success &&
                            sheetCtx.mounted &&
                            Navigator.of(
                              sheetCtx,
                              rootNavigator: true,
                            ).canPop()) {
                          Navigator.of(sheetCtx, rootNavigator: true).pop();
                        }
                      },
                      child: Text(
                        'Salvar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeGray,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final nameCtrl = TextEditingController(text: name);
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
      isDismissible: false,
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar fornecedor',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          validator: FormValidators.validateOptionalPhone,
                          inputFormatters: [PhoneInputFormatter()],
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themeGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        final fields = <String, dynamic>{
                          'name': nameCtrl.text.trim(),
                        };
                        if (docCtrl.text.trim().isNotEmpty) {
                          fields['docNumber'] = docCtrl.text.trim();
                        }
                        if (phoneCtrl.text.trim().isNotEmpty) {
                          fields['phone'] = phoneCtrl.text.trim();
                        }
                        if (emailCtrl.text.trim().isNotEmpty) {
                          fields['email'] = emailCtrl.text.trim();
                        }
                        if (notesCtrl.text.trim().isNotEmpty) {
                          fields['notes'] = notesCtrl.text.trim();
                        }
                        final success = await controller.updateSupplier(
                          id,
                          fields,
                        );
                        if (success &&
                            sheetCtx.mounted &&
                            Navigator.of(
                              sheetCtx,
                              rootNavigator: true,
                            ).canPop()) {
                          Navigator.of(sheetCtx, rootNavigator: true).pop();
                        }
                      },
                      child: Text(
                        'Salvar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeGray,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
