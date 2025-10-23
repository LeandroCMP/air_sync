import 'package:dartz/dartz.dart';
import 'package:air_sync/core/storage/local_database.dart';
import 'package:air_sync/features/orders/data/datasources/orders_local_data_source.dart';
import 'package:air_sync/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:air_sync/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:air_sync/features/orders/domain/repositories/orders_repository.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_mock_adapter/dio_http_mock_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late LocalDatabase database;
  late OrdersRepository repository;

  setUp(() async {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    database = LocalDatabase();
    await database.init();
    repository = OrdersRepositoryImpl(
      remoteDataSource: OrdersRemoteDataSource(dio),
      localDataSource: OrdersLocalDataSource(database),
    );
  });

  test('should fetch orders from API', () async {
    adapter.onGet('/v1/orders', (server) {
      server.reply(200, [
        {
          'id': '1',
          'status': 'scheduled',
          'clientName': 'Cliente Teste',
          'scheduledAt': '2024-01-01T12:00:00.000Z'
        },
      ]);
    });

    final result = await repository.list();

    expect(result.isRight(), true);
    expect(result.fold((l) => 0, (r) => r.length), 1);
  });
}
