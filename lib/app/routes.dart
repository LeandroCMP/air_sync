import 'package:get/get.dart';

import '../features/auth/presentation/bindings/auth_binding.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/clients/presentation/bindings/clients_binding.dart';
import '../features/clients/presentation/pages/client_detail_page.dart';
import '../features/clients/presentation/pages/client_list_page.dart';
import '../features/finance/presentation/bindings/finance_binding.dart';
import '../features/finance/presentation/pages/finance_page.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/inventory/presentation/bindings/inventory_binding.dart';
import '../features/inventory/presentation/pages/inventory_item_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/orders/presentation/bindings/orders_binding.dart';
import '../features/orders/presentation/pages/order_detail_page.dart';
import '../features/orders/presentation/pages/orders_page.dart';
import '../features/sync/presentation/bindings/sync_binding.dart';
import '../features/sync/presentation/pages/sync_page.dart';
import 'middlewares/auth_guard.dart';
import 'middlewares/rbac_guard.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const clients = '/clients';
  static const clientDetail = '/clients/:id';
  static const inventory = '/inventory';
  static const inventoryItem = '/inventory/:id';
  static const finance = '/finance';
  static const sync = '/sync';
  static const pdfViewer = '/pdf-viewer';
}

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.orders,
      page: () => const OrdersPage(),
      binding: OrdersBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailPage(),
      binding: OrdersBinding(),
      middlewares: [AuthGuard(), RBACGuard(requiredPermissions: ['orders.read'])],
    ),
    GetPage<dynamic>(
      name: AppRoutes.clients,
      page: () => const ClientListPage(),
      binding: ClientsBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.clientDetail,
      page: () => const ClientDetailPage(),
      binding: ClientsBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.inventory,
      page: () => const InventoryPage(),
      binding: InventoryBinding(),
      middlewares: [AuthGuard(), RBACGuard(requiredPermissions: ['inventory.read'])],
    ),
    GetPage<dynamic>(
      name: AppRoutes.inventoryItem,
      page: () => const InventoryItemPage(),
      binding: InventoryBinding(),
      middlewares: [AuthGuard(), RBACGuard(requiredPermissions: ['inventory.read'])],
    ),
    GetPage<dynamic>(
      name: AppRoutes.finance,
      page: () => const FinancePage(),
      binding: FinanceBinding(),
      middlewares: [AuthGuard(), RBACGuard(requiredPermissions: ['finance.read'])],
    ),
    GetPage<dynamic>(
      name: AppRoutes.sync,
      page: () => const SyncPage(),
      binding: SyncBinding(),
      middlewares: [AuthGuard()],
    ),
  ];
}
