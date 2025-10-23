import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/utils/validators.dart';
import '../../../../app/widgets/buttons.dart';
import '../controllers/client_detail_controller.dart';

class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({super.key});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final ClientDetailController controller;

  final name = TextEditingController();
  final document = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClientDetailController>();
    final id = Get.parameters['id'];
    if (id != null) {
      controller.load(id).then((_) {
        final client = controller.client.value;
        if (client != null) {
          name.text = client.name;
          document.text = client.document ?? '';
          phone.text = client.phones.isNotEmpty ? client.phones.first : '';
          email.text = client.emails.isNotEmpty ? client.emails.first : '';
        }
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    document.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? 'Novo Cliente' : 'Editar Cliente'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.client.value == null && id != null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: document,
                  decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
                  validator: Validators.cpfCnpj,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                Obx(() => PrimaryButton(
                      label: 'Salvar',
                      loading: controller.isLoading.value,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final data = {
                          'name': name.text,
                          'document': document.text,
                          'phones': [phone.text],
                          'emails': [email.text],
                        };
                        final saved = await controller.save(id: id, payload: data);
                        if (saved != null) {
                          Get.back(result: saved);
                        }
                      },
                    )),
              ],
            ),
          ),
        );
      }),
    );
  }
}
