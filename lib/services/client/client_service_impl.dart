import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/services/client/client_service.dart';

class ClientServiceImpl implements ClientService {
  final ClientRepository _clientRepository;

  ClientServiceImpl({required ClientRepository clientRepository})
    : _clientRepository = clientRepository;

  @override
  Future<ClientModel> registerClient(ClientModel client) =>
      _clientRepository.registerClient(client);

  @override
  Future<List<ClientModel>> getClientsByUserId(String userId) =>
      _clientRepository.getClientsByUserId(userId);

  @override
  Future<void> updateClient(ClientModel client) =>
      _clientRepository.updateClient(client);
}
