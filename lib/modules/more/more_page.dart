import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/company_profile/company_profile_bindings.dart';
import 'package:air_sync/modules/company_profile/company_profile_page.dart';
import 'package:air_sync/modules/profile/user_profile_bindings.dart';
import 'package:air_sync/modules/profile/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncService>();
    final queue = Get.find<QueueService>();
    final auth = Get.find<AuthServiceApplication>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: Obx(
        () {
          final isOwner = auth.user.value?.isOwner ?? false;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.white70),
                title: const Text(
                  'Sincronizar agora',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Obx(() {
                  final last = sync.lastSync.value;
                  return Text(
                    last == null ? 'Nunca' : 'Último: ${last.toLocal()}',
                    style: const TextStyle(color: Colors.white70),
                  );
                }),
                onTap: () => sync.syncInitial(),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white70),
                title: const Text(
                  'Meu perfil',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Atualize nome, e-mail e senha',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => Get.to(
                  () => const UserProfilePage(),
                  binding: UserProfileBindings(),
                ),
              ),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.white70),
                  title: const Text(
                    'Perfil da empresa',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Defina PIX e taxas por forma de pagamento',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Get.to(
                    () => const CompanyProfilePage(),
                    binding: CompanyProfileBindings(),
                  ),
                ),
              Obx(
                () => ListTile(
                  leading:
                      const Icon(Icons.upload_rounded, color: Colors.white70),
                  title: const Text(
                    'Ações pendentes',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: CircleAvatar(
                    radius: 12,
                    backgroundColor: context.themeGreen,
                    child: Text(
                      queue.pending.length.toString(),
                      style: TextStyle(
                        color: context.themeGray,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => queue.processPending(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
