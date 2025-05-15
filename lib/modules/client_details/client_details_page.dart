import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cep_input_formatter.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './client_details_controller.dart';

class ClientDetailsPage extends GetView<ClientDetailsController> {
  const ClientDetailsPage({super.key});

  void showAddResidenceModal(
    BuildContext context,
    ClientDetailsController controller,
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
                    'Cadastrar Endereço',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller.residenceCtrl,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Nome do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextFormField(
                    controller: controller.zipCodeCtrl,
                    inputFormatters: [CepInputFormatter()],
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o cep do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'CEP',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextFormField(
                    controller: controller.cityCtrl,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe a cidade do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextFormField(
                    controller: controller.streetCtrl,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe a rua do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Rua',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextFormField(
                    controller: controller.numberCtrl,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o número do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextFormField(
                    controller: controller.complementCtrl,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Informe o complemento do endereço'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
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
                        controller.getZipCode();
                        if (formKey.currentState!.validate()) {
                          await controller.registerResidence();
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
        title: Text(
          'Cliente',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        leading: IconButton(
          onPressed: () => controller.backToClients(),
          icon: Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        backgroundColor: context.themeDark,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add, size: 42),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: context.themeGreen,
          shape: const CircleBorder(),
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.close, size: 42),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
        ),
        children: [
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.red,
            child: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {},
          ),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.yellow,
            child: Icon(Icons.phone, color: Colors.black),
            onPressed:
                () => controller.launchDialer(controller.client.value.phone),
          ),

          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {},
          ),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: context.themeGreen,
            child: Icon(Icons.add, color: Colors.white),
            onPressed: () => showAddResidenceModal(context, controller),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: context.themeGray,
              leading: CircleAvatar(
                backgroundColor: context.themeLightGray,
                child: Icon(Icons.person_outlined, color: Colors.white),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_outlined,
                color: context.themeLightGray,
              ),
              title: Obx(() {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.client.value.name,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      '${controller.client.value.residences.length} Endereços',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '${controller.totalAirConditioners} Equipamentos',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 30),
            Obx(() {
              return controller.client.value.residences.isEmpty
                  ? Expanded(
                    child: Center(
                      child: Text(
                        "Nenhum endereço cadastrado!",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                  : Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    direction: Axis.horizontal,
                    children:
                        controller.client.value.residences.map((residence) {
                          return InkWell(
                            onTap: () => Get.toNamed(
                              '/client/details/airconditioner',
                               arguments: controller.client.value,),
                            child: Container(
                              height: 125,
                              width: 150,
                              decoration: BoxDecoration(
                                color: context.themeGray,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.maps_home_work_outlined,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    residence.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
            }),
          ],
        ),
      ),
    );
  }
}
