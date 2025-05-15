import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cpf_cnpj_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/phone_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import './client_controller.dart';

class ClientPage extends GetView<ClientController> {
  const ClientPage({super.key});

  void showAddClientModal(BuildContext context, ClientController controller) {
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
                    'Cadastrar Cliente',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller.nameController,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o nome'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: controller.phoneController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o telefone'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o CPF ou CNPJ'
                                : null,
                    inputFormatters: [CpfCnpjInputFormatter()],
                    controller: controller.cpfOrCnpjController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'CPF ou CNPJ',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: controller.birthDateController,
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(data: ThemeData.dark(), child: child!);
                        },
                      );
                      if (pickedDate != null) {
                        controller.birthDateController.text =
                            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                        controller.birthDate(pickedDate);
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: Icon(Icons.calendar_month_outlined),
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
                          await controller.registerClient();
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
        centerTitle: true,
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: () => showAddClientModal(context, controller),
        child: const Icon(Icons.add, color: Colors.white, size: 42),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Obx(() {
          if (controller.clients.isEmpty && controller.isLoading.isFalse) {
            return const Center(
              child: Text(
                'Nenhum cliente encontrado!',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            );
          }
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemCount: controller.clients.length,
            itemBuilder: (context, index) {
              final client = controller.clients[index];
              return InkWell(
                onTap: () => Get.toNamed('/client/details', arguments: client),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: context.themeLightGray,
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                client.phone,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${client.residences.isNotEmpty ? client.residences[0].airConditioners.length : 0} Equipamentos',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
