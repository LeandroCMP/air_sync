import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/services/client/client_service.dart';

class ClientServiceImpl implements ClientService {
  final ClientRepository _clientRepository;

  ClientServiceImpl({required ClientRepository clientRepository})
    : _clientRepository = clientRepository;

  @override
  Future<void> registerClient(ClientModel client) =>
      _clientRepository.registerClient(client);

  @override
  Future<List<ClientModel>> getClientsByUserId(String userId) =>
      _clientRepository.getClientsByUserId(userId);
}
