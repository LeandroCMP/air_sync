import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../app/interceptors/auth_interceptor.dart';
import '../app/interceptors/logging_interceptor.dart';
import '../app/interceptors/retry_interceptor.dart';
import '../app/interceptors/tenant_interceptor.dart';
import '../app/services/file_service.dart';
import '../app/services/network_info.dart';
import '../core/auth/session_manager.dart';
import '../core/auth/token_storage.dart';
import '../core/storage/local_database.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_session_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../features/clients/data/datasources/clients_local_data_source.dart';
import '../features/clients/data/datasources/clients_remote_data_source.dart';
import '../features/clients/data/repositories/clients_repository_impl.dart';
import '../features/clients/domain/repositories/clients_repository.dart';
import '../features/clients/domain/usecases/create_client_usecase.dart';
import '../features/clients/domain/usecases/delete_client_usecase.dart';
import '../features/clients/domain/usecases/get_client_detail_usecase.dart';
import '../features/clients/domain/usecases/get_clients_usecase.dart';
import '../features/clients/domain/usecases/update_client_usecase.dart';
import '../features/finance/data/datasources/finance_local_data_source.dart';
import '../features/finance/data/datasources/finance_remote_data_source.dart';
import '../features/finance/data/repositories/finance_repository_impl.dart';
import '../features/finance/domain/repositories/finance_repository.dart';
import '../features/finance/domain/usecases/get_dre_usecase.dart';
import '../features/finance/domain/usecases/get_finance_kpis_usecase.dart';
import '../features/finance/domain/usecases/get_finance_transactions_usecase.dart';
import '../features/finance/domain/usecases/pay_transaction_usecase.dart';
import '../features/inventory/data/datasources/inventory_local_data_source.dart';
import '../features/inventory/data/datasources/inventory_remote_data_source.dart';
import '../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/inventory/domain/usecases/get_inventory_item_usecase.dart';
import '../features/inventory/domain/usecases/get_inventory_items_usecase.dart';
import '../features/inventory/domain/usecases/get_low_stock_usecase.dart';
import '../features/inventory/domain/usecases/move_inventory_usecase.dart';
import '../features/orders/data/datasources/orders_local_data_source.dart';
import '../features/orders/data/datasources/orders_remote_data_source.dart';
import '../features/orders/data/repositories/orders_repository_impl.dart';
import '../features/orders/domain/repositories/orders_repository.dart';
import '../features/orders/domain/usecases/create_order_usecase.dart';
import '../features/orders/domain/usecases/deduct_materials_usecase.dart';
import '../features/orders/domain/usecases/finish_order_usecase.dart';
import '../features/orders/domain/usecases/get_order_detail_usecase.dart';
import '../features/orders/domain/usecases/get_orders_usecase.dart';
import '../features/orders/domain/usecases/reserve_materials_usecase.dart';
import '../features/orders/domain/usecases/start_order_usecase.dart';
import '../features/orders/domain/usecases/update_order_usecase.dart';
import '../features/sync/data/datasources/sync_remote_data_source.dart';
import '../features/sync/data/repositories/sync_repository_impl.dart';
import '../features/sync/domain/repositories/sync_repository.dart';
import '../features/sync/domain/usecases/process_sync_queue_usecase.dart';
import '../features/sync/domain/usecases/sync_now_usecase.dart';

class DependencyConfig {
  Future<void> init({required LocalDatabase database}) async {
    Get.put<LocalDatabase>(database, permanent: true);

    final tokenStorage = TokenStorage(GetStorage());
    final sessionManager = SessionManager(tokenStorage);
    await sessionManager.hydrate();
    Get.put(tokenStorage, permanent: true);
    Get.put(sessionManager, permanent: true);

    final networkInfo = NetworkInfoImpl(Connectivity());
    Get.put<NetworkInfo>(networkInfo, permanent: true);
    Get.put(FileService(), permanent: true);

    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );
    Get.put<Dio>(dio, permanent: true);

    // Auth
    final authRemote = AuthRemoteDataSource(dio);
    final authRepository = AuthRepositoryImpl(remoteDataSource: authRemote, sessionManager: sessionManager);
    Get.put<AuthRepository>(authRepository, permanent: true);
    Get.put(LoginUseCase(authRepository), permanent: true);
    final refreshTokenUseCase = RefreshTokenUseCase(authRepository);
    Get.put(refreshTokenUseCase, permanent: true);
    Get.put(LogoutUseCase(authRepository), permanent: true);
    Get.put(GetSessionUseCase(sessionManager), permanent: true);

    dio.interceptors.addAll([
      TenantInterceptor(sessionManager),
      AuthInterceptor(sessionManager: sessionManager, refreshTokenUseCase: refreshTokenUseCase, dio: dio),
      RetryInterceptor(dio: dio),
      if (kDebugMode) LoggingInterceptor(),
    ]);

    // Clients
    final clientsRemote = ClientsRemoteDataSource(dio);
    final clientsLocal = ClientsLocalDataSource(database);
    final clientsRepository = ClientsRepositoryImpl(remoteDataSource: clientsRemote, localDataSource: clientsLocal);
    Get.put<ClientsRepository>(clientsRepository, permanent: true);
    Get.put(GetClientsUseCase(clientsRepository));
    Get.put(GetClientDetailUseCase(clientsRepository));
    Get.put(CreateClientUseCase(clientsRepository));
    Get.put(UpdateClientUseCase(clientsRepository));
    Get.put(DeleteClientUseCase(clientsRepository));

    // Orders
    final ordersRemote = OrdersRemoteDataSource(dio);
    final ordersLocal = OrdersLocalDataSource(database);
    final ordersRepository = OrdersRepositoryImpl(remoteDataSource: ordersRemote, localDataSource: ordersLocal);
    Get.put<OrdersRepository>(ordersRepository, permanent: true);
    Get.put(GetOrdersUseCase(ordersRepository));
    Get.put(GetOrderDetailUseCase(ordersRepository));
    Get.put(CreateOrderUseCase(ordersRepository));
    Get.put(UpdateOrderUseCase(ordersRepository));
    Get.put(StartOrderUseCase(ordersRepository));
    Get.put(FinishOrderUseCase(ordersRepository));
    Get.put(ReserveMaterialsUseCase(ordersRepository));
    Get.put(DeductMaterialsUseCase(ordersRepository));

    // Inventory
    final inventoryRemote = InventoryRemoteDataSource(dio);
    final inventoryLocal = InventoryLocalDataSource(database);
    final inventoryRepository = InventoryRepositoryImpl(remoteDataSource: inventoryRemote, localDataSource: inventoryLocal);
    Get.put<InventoryRepository>(inventoryRepository, permanent: true);
    Get.put(GetInventoryItemsUseCase(inventoryRepository));
    Get.put(GetInventoryItemUseCase(inventoryRepository));
    Get.put(MoveInventoryUseCase(inventoryRepository));
    Get.put(GetLowStockUseCase(inventoryRepository));

    // Finance
    final financeRemote = FinanceRemoteDataSource(dio);
    final financeLocal = FinanceLocalDataSource(database);
    final financeRepository = FinanceRepositoryImpl(remoteDataSource: financeRemote, localDataSource: financeLocal);
    Get.put<FinanceRepository>(financeRepository, permanent: true);
    Get.put(GetFinanceTransactionsUseCase(financeRepository));
    Get.put(PayTransactionUseCase(financeRepository));
    Get.put(GetDreUseCase(financeRepository));
    Get.put(GetFinanceKpisUseCase(financeRepository));

    // Sync
    final syncRemote = SyncRemoteDataSource(dio);
    final syncRepository = SyncRepositoryImpl(remoteDataSource: syncRemote, database: database);
    Get.put<SyncRepository>(syncRepository, permanent: true);
    Get.put(SyncNowUseCase(syncRepository));
    Get.put(ProcessSyncQueueUseCase(syncRepository));
  }
}
