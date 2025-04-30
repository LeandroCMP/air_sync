
import 'package:air_sync/models/client_model.dart';

abstract class ClientService {
  Future<void> registerClient(ClientModel client);
   Future<List<ClientModel>> getClientsByUserId(String userId);
}