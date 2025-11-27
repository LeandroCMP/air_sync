import 'package:air_sync/application/auth/auth_service_application.dart';
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
    final border = BorderSide(color: context.themeBorder);
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
                  // ================= KPI STRIP =================
                  SizedBox(
                    height: 118,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        _KpiChip(
                          label: 'OS abertas',
                          value: '--',
                          icon: Icons.assignment_rounded,
                          colorHex: 0xFF4DA3FF,
                        ),
                        _KpiChip(
                          label: 'Pendentes',
                          value: '--',
                          icon: Icons.schedule_rounded,
                          colorHex: 0xFFFFA15C,
                        ),
                        _KpiChip(
                          label: 'Atrasadas',
                          value: '--',
                          icon: Icons.warning_amber_rounded,
                          colorHex: 0xFFFFA15C,
                        ),
                        _KpiChip(
                          label: 'Hoje',
                          value: '--',
                          icon: Icons.today_rounded,
                          colorHex: 0xFF00B686,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const _QuickActionsRow(),
                  const SizedBox(height: 16),

                  // ============== GRID DE MÓDULOS (MAIS ALTO) ==============
                  GridView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.98,
                        ),
                    children: moduleCards,
                  ),

                  if (moduleCards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum módulo disponível para este usuário. Ajuste as permissões em Colaboradores.',
                        style: TextStyle(color: context.themeTextSubtle),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ================= DICA / RODAPÉ =================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.fromBorderSide(border),
                    ),
                    child: Text(
                      'Dica: abra um módulo para criar registros (ex.: criar OS dentro de "Ordens de Serviço").',
                      style: Theme.of(context).textTheme.bodySmall,
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
    title: 'Ordens de Servi?o',
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
    subtitle: 'Movimenta??es e itens',
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
    subtitle: 'Check, abastecimento e manuten??o',
    icon: Icons.local_shipping_outlined,
    requiredPermissions: ['fleet.read', 'fleet.write'],
    onTap: () => Get.toNamed('/fleet'),
  ),
  _ModuleCardData(
    title: 'Linha do tempo',
    subtitle: 'Eventos e atividades por cliente',
    icon: Icons.timeline_outlined,
    requiredPermissions: ['timeline.read', 'timeline.write'],
    onTap: () => Get.toNamed('/timeline'),
  ),
  _ModuleCardData(
    title: 'Colaboradores',
    subtitle: 'Permiss?es e holerites',
    icon: Icons.badge_outlined,
    requiredPermissions: ['users.write'],
    ownerOnly: true,
    onTap: () => Get.toNamed('/users'),
  ),
];

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int colorHex;
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(colorHex);
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthServiceApplication>();
    return Obx(() {
      final isOwner = auth.user.value?.isOwner ?? false;
      final actions = <_QuickActionData>[
        _QuickActionData(
          label: 'Meu perfil',
          icon: Icons.person_outline,
          onTap: () => Get.toNamed('/profile'),
        ),
        _QuickActionData(
          label: 'Nova OS',
          icon: Icons.add_task_outlined,
          onTap: () => Get.to(() => const OrdersPage(), binding: OrdersBindings()),
        ),
        _QuickActionData(
          label: 'Registrar compra',
          icon: Icons.point_of_sale,
          onTap: () => Get.toNamed('/purchases'),
        ),
        _QuickActionData(
          label: 'Financeiro',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => Get.to(() => const FinancePage()),
        ),
      ];
      if (isOwner) {
        actions.add(
          _QuickActionData(
            label: 'Assinaturas & Billing',
            icon: Icons.subscriptions_outlined,
            onTap: () => Get.toNamed('/subscriptions'),
          ),
        );
        actions.add(
          _QuickActionData(
            label: 'Perfil da empresa',
            icon: Icons.business_center_outlined,
            onTap: () => Get.to(
              () => const CompanyProfilePage(),
              binding: CompanyProfileBindings(),
            ),
          ),
        );
      }
      return SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (_, index) => _QuickActionButton(data: actions[index]),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: actions.length,
        ),
      );
    });
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(data.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

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
