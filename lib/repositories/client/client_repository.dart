import 'package:air_sync/models/client_model.dart';

abstract class ClientRepository {
  Future<List<ClientModel>> list({
    String? text,
    int page = 1,
    int limit = 20,
    bool includeDeleted = false,
  });

  Future<ClientModel> getById(String id);

  Future<ClientModel> create(ClientModel client);

  Future<ClientModel> update(ClientModel client, {ClientModel? original});

  Future<void> delete(String id);
}
