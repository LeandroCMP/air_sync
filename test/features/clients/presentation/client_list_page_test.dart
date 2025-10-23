import 'package:air_sync/features/clients/domain/entities/client.dart';
import 'package:air_sync/features/clients/domain/usecases/delete_client_usecase.dart';
import 'package:air_sync/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:air_sync/features/clients/presentation/controllers/client_list_controller.dart';
import 'package:air_sync/features/clients/presentation/pages/client_list_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetClientsUseCase extends Mock implements GetClientsUseCase {}

class _MockDeleteClientUseCase extends Mock implements DeleteClientUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
  });

  testWidgets('renders empty state when no clients', (tester) async {
    final getClients = _MockGetClientsUseCase();
    final deleteClient = _MockDeleteClientUseCase();
    when(() => getClients.call(text: anyNamed('text'))).thenAnswer((_) async => const Right(<Client>[]));
    when(() => deleteClient.call(any())).thenAnswer((_) async => const Right(null));

    Get.put<ClientListController>(ClientListController(getClients, deleteClient));

    await tester.pumpWidget(const GetMaterialApp(home: ClientListPage()));
    await tester.pump();

    expect(find.text('Cadastre seu primeiro cliente'), findsOneWidget);
  });
}
