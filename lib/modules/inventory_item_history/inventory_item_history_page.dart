import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './inventory_item_history_controller.dart';

class InventoryItemHistoryPage extends GetView<InventoryItemHistoryController> {
  const InventoryItemHistoryPage({super.key});

  void showAddHistoryModal(
    BuildContext context,
    InventoryItemHistoryController controller,
  ) {
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder: (_) => Padding(
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
              const Text(
                'Reposição de estoque',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.quantityToAddCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a quantidade' : null,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
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
                    if (formKey.currentState!.validate()) {
                      await controller.addRecordToItem();
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

  void confirmDeleteEntry(int index) {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1B1B1D),
      titleStyle: const TextStyle(color: Colors.white70),
      middleTextStyle: const TextStyle(color: Colors.white70),
      title: 'Confirmação',
      middleText: 'Tem certeza que deseja excluir este registro?',
      textConfirm: 'Sim',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      confirm: TextButton(
        onPressed: () {
          Get.back();
          controller.deleteRecordFromItemByIndex(index);
        },
        child: const Text(
          'Confirmar',
          style: TextStyle(color: Color(0xFF73D941)),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          'Cancelar',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void confirmDeleteItem() {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1B1B1D),
      titleStyle: const TextStyle(color: Colors.white70),
      middleTextStyle: const TextStyle(color: Colors.white70),
      title: 'Confirmação',
      middleText: 'Tem certeza que deseja excluir este item do estoque?',
      textConfirm: 'Sim',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      confirm: TextButton(
        onPressed: () {
          Get.back();
          controller.deleteItem();
        },
        child: const Text(
          'Confirmar',
          style: TextStyle(color: Color(0xFF73D941)),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          'Cancelar',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildEntryTile({
    required BuildContext context,
    required double quantity,
    required String unit,
    required DateTime date,
    required VoidCallback onDelete,
  }) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    return ListTile(
      leading: const Icon(Icons.calendar_month_outlined),
      trailing: InkWell(
        onTap: onDelete,
        child:  Icon(Icons.delete_outline_outlined, color: Colors.red[900],),
      ),
      iconColor: Colors.white70,
      textColor: Colors.white70,
      title: Text('$quantity $unit'),
      subtitle: Text(formattedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: context.themeDark,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: () => showAddHistoryModal(context, controller),
        child: const Icon(Icons.add, color: Colors.white, size: 42),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.themeGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Obx(() {
                final item = controller.item.value;
                return ListTile(
                  iconColor: Colors.white70,
                  textColor: Colors.white70,
                  leading: const Icon(Icons.build_sharp),
                  trailing: InkWell(
                    onTap: () => confirmDeleteItem(), 
                    child: Icon(Icons.delete_outline_outlined,
                    color: Colors.red[900],
                    ),
                    ),
                  title: Text(
                    item.description,
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    '${item.quantity} ${item.unit}',
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Obx(() {
              final item = controller.item.value;
              final entries = item.entries;

              if (entries.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Text(
                      'Nenhum registro de entrada encontrado!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ),
                );
              }

              return Expanded(
                child: Column(
                  children: [
                    Text('Registros de Entrada', style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      ),),
                      const SizedBox(height: 10,),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (context, index) => Divider(
                          color: context.themeLightGray,
                          height: 10,
                        ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final history = entries[index];
                          return _buildEntryTile(
                            context: context,
                            quantity: history.quantity,
                            unit: item.unit,
                            date: history.date,
                            onDelete: () => confirmDeleteEntry(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
