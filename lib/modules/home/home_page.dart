import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/modules/orders/orders_page.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/modules/finance/finance_page.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import './home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: context.themeBorder);

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
                          value: '—',
                          icon: Icons.assignment_rounded,
                          colorHex: 0xFF4DA3FF,
                        ),
                        _KpiChip(
                          label: 'Pendentes',
                          value: '—',
                          icon: Icons.schedule_rounded,
                          colorHex: 0xFFFFA15C,
                        ),
                        _KpiChip(
                          label: 'Atrasadas',
                          value: '—',
                          icon: Icons.warning_amber_rounded,
                          colorHex: 0xFFFFA15C,
                        ),
                        _KpiChip(
                          label: 'Hoje',
                          value: '—',
                          icon: Icons.today_rounded,
                          colorHex: 0xFF00B686,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============== GRID DE MÓDULOS (MAIS ALTO) ==============
                  GridView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.98, // ↑ mais alto = mais espaço p/ texto
                    ),
                    children: [
                      _ModuleCard(
                        title: 'Ordens de Serviço',
                        subtitle: 'Acompanhe e crie',
                        icon: Icons.assignment_rounded,
                        onTap: () => Get.to(() => const OrdersPage()),
                      ),
                      _ModuleCard(
                        title: 'Clientes',
                        subtitle: 'Cadastre e gerencie',
                        icon: Icons.group_rounded,
                        onTap: () => Get.toNamed('/client'),
                      ),
                      _ModuleCard(
                        title: 'Estoque',
                        subtitle: 'Movimentações e itens',
                        icon: Icons.inventory_2_rounded,
                        onTap: () => Get.toNamed('/inventory'),
                      ),
                      _ModuleCard(
                        title: 'Financeiro',
                        subtitle: 'Faturas e recebíveis',
                        icon: Icons.account_balance_wallet_rounded,
                        onTap: () => Get.to(() => const FinancePage()),
                      ),
                    ],
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
                      'Dica: abra um módulo para criar registros (ex.: criar OS dentro de “Ordens de Serviço”).',
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
                  Text('Bem-vindo de volta,', style: Theme.of(context).textTheme.bodySmall),
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
                        final online = Get.find<ConnectivityService>().isOnline.value;
                        return online
                            ? const SizedBox.shrink()
                            : const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 18);
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
            builder: (context) => IconButton(
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

// ======================= COMPONENTES =======================

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
      width: 165,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.themeTextMain,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: context.themeTextSubtle),
          ),
        ],
      ),
    );
  }
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
    return LayoutBuilder(
      builder: (context, c) {
        // Modo compacto: cards estreitos (duas colunas em telas 360–411dp)
        final isCompact = c.maxWidth < 190;

        // Tokens responsivos
        final titleFont = isCompact ? 15.5 : 16.5;
        final subtitleFont = isCompact ? 13.0 : 13.5;
        final iconSize = isCompact ? 26.0 : 28.0;
        final iconBox = isCompact ? 48.0 : 56.0;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.themeBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            // 👉 Layout muda conforme a largura:
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: isCompact
                  // ====== LAYOUT COMPACTO: ÍCONE EM CIMA, TEXTO ABAIXO ======
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: iconBox,
                          width: iconBox,
                          decoration: BoxDecoration(
                            color: context.themeSurfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: context.themeTextMain.withOpacity(0.9), size: iconSize),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2, // agora aceita 2 linhas
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextMain,
                            height: 1.16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subtitleFont,
                            color: context.themeTextSubtle,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white54),
                        ),
                      ],
                    )
                  // ====== LAYOUT LARGO: ÍCONE AO LADO, TEXTO EM 1 LINHA ======
                  : Row(
                      children: [
                        Container(
                          height: iconBox,
                          width: iconBox,
                          decoration: BoxDecoration(
                            color: context.themeSurfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: context.themeTextMain.withOpacity(0.9), size: iconSize),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: titleFont,
                                  fontWeight: FontWeight.w600,
                                  color: context.themeTextMain,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleFont,
                                  color: context.themeTextSubtle,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white54),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ======================= DRAWER =======================

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();
  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncService>();
    final queue = Get.find<QueueService>();
    return Drawer(
      backgroundColor: context.themeSurface,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Mais', style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(height: 24, color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sincronizar agora'),
            subtitle: Obx(() {
              final last = sync.lastSync.value;
              return Text(
                last == null ? 'Nunca' : 'Último: ${last.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }),
            onTap: () async {
              await sync.syncInitial();
              if (context.mounted) Navigator.of(context).maybePop();
            },
          ),
          Obx(() => ListTile(
                leading: const Icon(Icons.upload_rounded),
                title: const Text('Ações pendentes'),
                trailing: CircleAvatar(
                  radius: 12,
                  backgroundColor: context.themePrimary,
                  child: Text(
                    queue.pending.length.toString(),
                    style: TextStyle(color: context.themeBg, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () async {
                  await queue.processPending();
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              )),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'AirSync • Dev Build',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white38),
            ),
          ),
        ]),
      ),
    );
  }
}
