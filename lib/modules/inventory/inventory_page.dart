import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './inventory_controller.dart';

class InventoryPage extends GetView<InventoryController> {
  const InventoryPage({super.key});

  void showAddItemModal(BuildContext context, InventoryController controller) {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cadastrar Item',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller.descriptionController,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o item'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.quantityController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Informe a quantidade'
                                      : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Informe a unidade de medida'
                                      : null,
                          controller: controller.unitController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Unidade de medida',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
                        if (formKey.currentState!.validate()) {
                          await controller.registerItem();
                        }
                      },
                      child: Text(
                        "Cadastrar",
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
                    onPressed: () {
                      controller.clearForm();
                      Get.back();
                    },
                    child: Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: context.themeDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: () => showAddItemModal(context, controller),
        child: const Icon(Icons.add, color: Colors.white, size: 42),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          if (controller.items.isEmpty && controller.isLoading.isFalse) {
            return const Center(
              child: Text(
                'Nenhum item encontrado!',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          }
          return ListView.separated(
            physics: BouncingScrollPhysics(),
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return Container(
                decoration: BoxDecoration(
                  color: context.themeGray, // Cor de fundo
                  borderRadius: BorderRadius.circular(12), // Borda arredondada
                ),
                child: ListTile(
                  onTap: () => Get.toNamed('/inventory/item', arguments: item),
                  iconColor: Colors.white70,
                  textColor: Colors.white70,
                  leading: Icon(Icons.assignment_outlined, size: 32),
                  title: Text(item.description),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  trailing: Icon(Icons.arrow_forward_ios_outlined),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
