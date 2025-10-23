import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes.dart';
import '../../../../app/widgets/buttons.dart';
import '../../../../app/utils/validators.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? tenantId = Get.parameters['tenant'];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('login_title'.tr, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'email'.tr, prefixIcon: const Icon(Icons.mail_outline)),
                    onChanged: controller.email.call,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'password'.tr, prefixIcon: const Icon(Icons.lock_outline)),
                    obscureText: true,
                    onChanged: controller.password.call,
                    validator: Validators.requiredField,
                  ),
                  const SizedBox(height: 16),
                  if (tenantId == null)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tenant ID (opcional)', prefixIcon: Icon(Icons.apartment)),
                      onChanged: (value) => tenantId = value,
                    ),
                  const SizedBox(height: 24),
                  Obx(
                    () => PrimaryButton(
                      label: 'enter'.tr,
                      loading: controller.isLoading.value,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final success = await controller.submit(tenantId: tenantId);
                        if (success && context.mounted) {
                          Get.offAllNamed(AppRoutes.home);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
