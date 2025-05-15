import 'package:air_sync/models/client_model.dart';

abstract class ClientRepository {
  Future<ClientModel> registerClient(ClientModel client);
  Future<List<ClientModel>> getClientsByUserId(String userId);
  Future<void> updateClient(ClientModel client);
}
