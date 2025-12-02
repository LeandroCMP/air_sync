import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/modules/orders/orders_bindings.dart';
import 'package:air_sync/modules/orders/orders_page.dart';
import 'package:air_sync/modules/company_profile/company_profile_bindings.dart';
import 'package:air_sync/modules/company_profile/company_profile_page.dart';
import 'package:air_sync/modules/finance/finance_page.dart';
import 'package:air_sync/modules/sales/sales_bindings.dart';
import 'package:air_sync/modules/sales/sales_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = controller.user.value;
    final moduleCards =
        _homeModuleItems
            .where((item) => item.canAccess(currentUser))
            .map(
              (item) => _ModuleCard(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                onTap: item.onTap,
              ),
            )
            .toList();

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: const _HomeAppBar(),
      endDrawer: const _HomeDrawer(),
      body: Obx(
        () => Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(user: currentUser),
                  const SizedBox(height: 20),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: moduleCards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (_, idx) => moduleCards[idx],
                  ),

                  if (moduleCards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum módulo disponível para este usuário. Ajuste as permissões em Colaboradores.',
                        style: TextStyle(color: context.themeTextSubtle),
                      ),
                    ),
                ],
              ),
            ),

            if (controller.isSyncing.value)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================= APP BAR =======================

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const FlutterLogo(size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo de volta,',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Get.find<HomeController>().user.value?.name ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final online =
                            Get.find<ConnectivityService>().isOnline.value;
                        return online
                            ? const SizedBox.shrink()
                            : const Icon(
                              Icons.wifi_off,
                              color: Colors.orangeAccent,
                              size: 18,
                            );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

// ======================= DRAWER =======================

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncService>();
    final queue = Get.find<QueueService>();
    final homeController = Get.find<HomeController>();
    return Drawer(
      child: SafeArea(
        child: ListView(
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
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.business_center_outlined,
                color: Colors.white70,
              ),
              title: const Text(
                'Perfil da empresa',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'PIX e taxas dos pagamentos',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(
                  () => const CompanyProfilePage(),
                  binding: CompanyProfileBindings(),
                );
              },
            ),
            Obx(
              () => ListTile(
                leading: const Icon(
                  Icons.upload_rounded,
                  color: Colors.white70,
                ),
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
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sair', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.of(context).pop();
                await homeController.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= COMPONENTES =======================



class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncService>();
    final isOnline = Get.find<ConnectivityService>().isOnline.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0f172a),
            const Color(0xFF0d9488).withValues(alpha: .85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                child: Text(
                  (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user?.name.split(' ').first ?? 'Airsyncer'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: 16,
                          color: isOnline ? Colors.tealAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline ? Colors.white70 : Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: sync.isSyncing.value ? null : sync.syncInitial,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  sync.isSyncing.value ? 'Sincronizando...' : 'Sincronizar',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Escolha um módulo para começar:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCardData {
  _ModuleCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.requiredPermissions = const [],
    this.ownerOnly = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<String> requiredPermissions;
  final bool ownerOnly;

  bool canAccess(UserModel? user) {
    if (ownerOnly) {
      return user?.isOwner ?? false;
    }
    if (requiredPermissions.isEmpty) return true;
    if (user == null) return true;
    return user.hasAnyPermission(requiredPermissions);
  }
}

final List<_ModuleCardData> _homeModuleItems = [
  _ModuleCardData(
    title: 'Ordens de Serviço',
    subtitle: 'Acompanhe e crie',
    icon: Icons.assignment_rounded,
    requiredPermissions: ['orders.read', 'orders.write'],
    onTap: () => Get.to(() => const OrdersPage(), binding: OrdersBindings()),
  ),
  _ModuleCardData(
    title: 'Clientes',
    subtitle: 'Cadastre e gerencie',
    icon: Icons.group_rounded,
    requiredPermissions: ['clients.read', 'clients.write'],
    onTap: () => Get.toNamed('/client'),
  ),
  _ModuleCardData(
    title: 'Estoque',
    subtitle: 'Movimentações e itens',
    icon: Icons.inventory_2_rounded,
    requiredPermissions: ['inventory.read', 'inventory.write'],
    onTap: () => Get.toNamed('/inventory'),
  ),
  _ModuleCardData(
    title: 'Financeiro',
    subtitle: 'Faturas e recebíveis',
    icon: Icons.account_balance_wallet_rounded,
    requiredPermissions: ['finance.read', 'finance.write'],
    onTap: () => Get.to(() => const FinancePage()),
  ),
  _ModuleCardData(
    title: 'Assinaturas & Billing',
    subtitle: 'Planos, faturas e Stripe',
    icon: Icons.subscriptions_outlined,
    ownerOnly: true,
    onTap: () => Get.toNamed('/subscriptions'),
  ),
  _ModuleCardData(
    title: 'Fornecedores',
    subtitle: 'Cadastre e gerencie parceiros',
    icon: Icons.store_mall_directory_outlined,
    requiredPermissions: [],
    onTap: () => Get.toNamed('/suppliers'),
  ),
  _ModuleCardData(
    title: 'Compras',
    subtitle: 'Itens e custos por pedido',
    icon: Icons.shopping_cart_outlined,
    requiredPermissions: [],
    onTap: () => Get.toNamed('/purchases'),
  ),
  _ModuleCardData(
    title: 'Vendas',
    subtitle: 'Propostas e assistente comercial',
    icon: Icons.sell_outlined,
    requiredPermissions: ['sales.read', 'sales.write'],
    onTap: () => Get.to(
      () => const SalesPage(),
      binding: SalesBindings(),
    ),
  ),
  _ModuleCardData(
    title: 'Contratos',
    subtitle: 'Planos e SLAs de clientes',
    icon: Icons.handshake_outlined,
    requiredPermissions: ['contracts.read', 'contracts.write'],
    onTap: () => Get.toNamed('/contracts'),
  ),
  _ModuleCardData(
    title: 'Frota',
    subtitle: 'Check, abastecimento e manutenção',
    icon: Icons.local_shipping_outlined,
    requiredPermissions: ['fleet.read', 'fleet.write'],
    onTap: () => Get.toNamed('/fleet'),
  ),
  _ModuleCardData(
    title: 'Colaboradores',
    subtitle: 'Permissões e holerites',
    icon: Icons.badge_outlined,
    requiredPermissions: ['users.write'],
    ownerOnly: true,
    onTap: () => Get.toNamed('/users'),
  ),
];

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
