import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/repositories/client/client_repository.dart';

import 'client_service.dart';

class ClientServiceImpl implements ClientService {
  ClientServiceImpl({required ClientRepository clientRepository})
    : _clientRepository = clientRepository;

  final ClientRepository _clientRepository;

  @override
  Future<List<ClientModel>> list({
    String? text,
    int page = 1,
    int limit = 20,
    bool includeDeleted = false,
  }) {
    return _clientRepository.list(
      text: text,
      page: page,
      limit: limit,
      includeDeleted: includeDeleted,
    );
  }

  @override
  Future<ClientModel> getById(String id) => _clientRepository.getById(id);

  @override
  Future<ClientModel> create(ClientModel client) =>
      _clientRepository.create(client);

  @override
  Future<ClientModel> update(ClientModel client, {ClientModel? original}) {
    return _clientRepository.update(client, original: original);
  }

  @override
  Future<void> delete(String id) => _clientRepository.delete(id);
}
