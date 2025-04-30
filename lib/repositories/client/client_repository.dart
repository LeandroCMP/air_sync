
import 'package:air_sync/models/client_model.dart';

abstract class ClientRepository {
  Future<void> registerClient(ClientModel client);
  Future<List<ClientModel>> getClientsByUserId(String userId);

}
