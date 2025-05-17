import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './air_conditioner_controller.dart';

class AirConditionerPage extends GetView<AirConditionerController> {
    
    const AirConditionerPage({super.key});

    void showAddAirConditionerModal(BuildContext context, AirConditionerController controller) {
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
                    //controller: controller.nameController,
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
                   // controller: controller.phoneController,
                   
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
                    //inputFormatters: [CpfCnpjInputFormatter()],
                    //controller: controller.cpfOrCnpjController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'CPF ou CNPJ',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    //controller: controller.birthDateController,
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
                         // await controller.registerClient();
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
                      //controller.clearForm();
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
              iconTheme: IconThemeData(color: Colors.white70),
              backgroundColor: context.themeDark,
              centerTitle: true,
              title: Text('Equipamentos', 
              style: TextStyle(color: Colors.white),),
              elevation: 0,
              ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: context.themeGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              onPressed: () => showAddAirConditionerModal(context, controller),
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
                    child: ListTile(
                      iconColor: Colors.white70,
                      leading: Icon(
                        Icons.maps_home_work_outlined,
                        size: 32,
                        ),
                      contentPadding: EdgeInsets.all(10),
                      trailing: InkWell(
                        onTap: (){},
                        child: Icon(
                          Icons.delete_outline_sharp, 
                          color: Colors.red[900],
                          size: 28,
                          ),
                      ),
                      title: Text(
                        controller.residence.value.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                        'Equipamentos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white,fontSize: 20,
                        ),
                      ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 10, child: Divider(color: Colors.white70,),
                        ),
                      itemCount: controller.residence.value.airConditioners.length,
                      itemBuilder: (context, index) {
                       return Container(height: 100, width: 100, color: Colors.red,);
                      }, 
                    ),
                  ),
                ],
              ),
            ),
        );
    }
}