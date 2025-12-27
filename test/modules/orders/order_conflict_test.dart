import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/order_costs_model.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/models/create_order_purchase_dto.dart';
import 'package:air_sync/models/order_draft_model.dart';
import 'package:air_sync/modules/orders/order_create_controller.dart';
import 'package:air_sync/modules/orders/order_detail_controller.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/services/orders/order_draft_storage.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/maintenance/maintenance_service.dart';
import 'package:air_sync/models/maintenance_service_type.dart';
import 'package:air_sync/models/maintenance_reminder_model.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _ConflictOrdersService implements OrdersService {
  _ConflictOrdersService({
    this.createError,
    this.rescheduleError,
  });

  final dio.DioException? createError;
  final dio.DioException? rescheduleError;

  @override
  Future<OrderModel> create({
    required String clientId,
    required String locationId,
    String? equipmentId,
    String? status,
    DateTime? scheduledAt,
    String? notes,
    List<String> technicianIds = const [],
    List<OrderChecklistInput> checklist = const [],
    List<OrderMaterialInput> materials = const [],
    List<OrderBillingItemInput> billingItems = const [],
    num billingDiscount = 0,
  }) async {
    if (createError != null) throw createError!;
    return _fakeOrder(id: 'created', scheduledAt: scheduledAt, techs: technicianIds);
  }

  @override
  Future<OrderModel> reschedule({
    required String orderId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    if (rescheduleError != null) throw rescheduleError!;
    return _fakeOrder(id: orderId, scheduledAt: scheduledAt);
  }

  OrderModel _fakeOrder({
    required String id,
    DateTime? scheduledAt,
    List<String> techs = const [],
  }) {
    return OrderModel(
      id: id,
      clientId: 'client-1',
      locationId: 'loc-1',
      status: 'scheduled',
      scheduledAt: scheduledAt,
      technicianIds: techs,
      checklist: const [],
      materials: const [],
      billing: OrderBilling.empty(),
      timesheet: OrderTimesheet.empty(),
      photoUrls: const [],
      audit: OrderAudit.empty(),
      payments: const [],
    );
  }

  // Unused interface methods for these tests
  @override
  Future<List<OrderModel>> list({
    DateTime? from,
    DateTime? to,
    String? status,
    String? technicianId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OrderModel> getById(String id) => throw UnimplementedError();

  @override
  Future<OrderModel> update({
    required String orderId,
    String? status,
    DateTime? scheduledAt,
    List<String>? technicianIds,
    List<OrderChecklistInput>? checklist,
    List<OrderBillingItemInput>? billingItems,
    num? billingDiscount,
    String? notes,
    String? clientId,
    String? locationId,
    String? equipmentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OrderModel> start(String orderId) => throw UnimplementedError();

  @override
  Future<OrderModel> finish({
    required String orderId,
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
    List<OrderPaymentInput> payments = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> reserveMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deductMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPhoto({
    required String orderId,
    required String filename,
    required List<int> bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadSignature({
    required String orderId,
    required String base64,
  }) {
    throw UnimplementedError();
  }

  @override
  String pdfUrl(String orderId, {String type = 'report'}) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String orderId) => throw UnimplementedError();

  @override
  Future<OrderCostsModel?> getCosts(String orderId) => throw UnimplementedError();

  @override
  Future<PurchaseModel> createPurchaseFromOrder({
    required String orderId,
    required CreateOrderPurchaseDto dto,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> askTechnicalAssistant({
    required String orderId,
    required String question,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> generateCustomerSummary(String orderId) {
    throw UnimplementedError();
  }
}

class _PassthroughLabeler implements OrderLabelService {
  @override
  Future<OrderModel> enrich(OrderModel order) async => order;

  @override
  Future<List<OrderModel>> enrichAll(Iterable<OrderModel> orders) async =>
      orders.toList();
}

class _NoopDraftStorage implements OrderDraftStorage {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<OrderDraftModel>> getAll() async => const [];

  @override
  Future<OrderDraftModel?> getById(String id) async => null;

  @override
  Future<void> save(OrderDraftModel draft) async {}
}

class _NoopClientService implements ClientService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopLocationsService implements LocationsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopEquipmentsService implements EquipmentsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopInventoryService implements InventoryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopUsersService implements UsersService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopMaintenanceService implements MaintenanceService {
  @override
  List<MaintenanceServiceType> cachedServiceTypes() => const [];

  @override
  Future<List<MaintenanceServiceType>> listServiceTypes({bool forceRefresh = false}) async =>
      const [];

  @override
  Future<List<MaintenanceReminderModel>> listReminders({
    required String equipmentId,
    String status = 'pending',
  }) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;

  dio.DioException conflictError(String path) {
    final req = dio.RequestOptions(path: path);
    return dio.DioException(
      requestOptions: req,
      response: dio.Response(
        requestOptions: req,
        statusCode: 400,
        data: {
          'code': 'TECH_ALREADY_BOOKED',
          'message': 'Tecnico ja possui OS neste horario.',
          'details': {
            'orderId': 'order-abc',
            'technicianIds': ['tech-1'],
          },
        },
      ),
      type: dio.DioExceptionType.badResponse,
    );
  }

  testWidgets('criar OS exibe conflito de tecnico ja agendado', (tester) async {
    final orders = _ConflictOrdersService(createError: conflictError('/v1/orders'));
    final controller = OrderCreateController(
      ordersService: orders,
      clientService: _NoopClientService(),
      locationsService: _NoopLocationsService(),
      equipmentsService: _NoopEquipmentsService(),
      inventoryService: _NoopInventoryService(),
      labelService: _PassthroughLabeler(),
      usersService: _NoopUsersService(),
      draftStorage: _NoopDraftStorage(),
      maintenanceService: _NoopMaintenanceService(),
    );
    controller.onInit();

    controller.clients.assignAll([
      ClientModel(
        id: 'client-1',
        name: 'Tester',
        emails: const ['tester@example.com'],
      ),
    ]);
    controller.locations.assignAll(
      [
        LocationModel(id: 'loc-1', clientId: 'client-1', label: 'Local'),
      ],
    );
    controller.selectedClientId.value = 'client-1';
    controller.selectedLocationId.value = 'loc-1';
    controller.technicians.assignAll(
      [
        CollaboratorModel(
          id: 'tech-1',
          name: 'Tecnico',
          email: 'tech@example.com',
          role: CollaboratorRole.tech,
          permissions: const [],
          active: true,
        ),
      ],
    );
    controller.selectedTechnicianIds.assignAll(const ['tech-1']);
    controller.setScheduledAt(DateTime(2025, 1, 1, 10, 0));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Form(
          key: controller.formKey,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await controller.submit();
    await tester.pump();

    expect(controller.bookingConflict.value, isNotNull);
    expect(controller.bookingConflict.value!.orderId, 'order-abc');
    expect(controller.message.value?.title, 'Conflito de agenda');
    expect(controller.message.value?.message, contains('tecnico'));
  });

  test('reagendar OS retorna conflito para UI', () async {
    final orders = _ConflictOrdersService(
      rescheduleError: conflictError('/v1/orders/reschedule'),
    );
    final controller = OrderDetailController(
      orderId: 'order-1',
      service: orders,
      labelService: null,
      inventoryService: null,
      clientService: null,
      locationsService: null,
      equipmentsService: null,
      companyProfileService: null,
      usersService: _NoopUsersService(),
      ordersController: null,
    );
    controller.onInit();

    final ok = await controller.rescheduleOrder(
      scheduledAt: DateTime(2025, 2, 10, 9, 30),
    );

    expect(ok, isFalse);
    expect(controller.bookingConflict.value, isNotNull);
    expect(controller.bookingConflict.value!.technicianIds, contains('tech-1'));
    expect(controller.message.value?.title, 'Conflito de agenda');
  });
}
