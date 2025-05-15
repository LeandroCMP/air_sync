import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/application/core/errors/client_failure.dart';
import 'client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ClientModel>> getClientsByUserId(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('clients')
              .where('userId', isEqualTo: userId)
              .get();

      return querySnapshot.docs.map((doc) {
        return ClientModel.fromMap(doc.id, doc.data());
      }).toList();
    } on FirebaseException catch (e) {
      throw ClientFailure.firebase('Erro ao buscar clientes: ${e.message}');
    } catch (e) {
      throw ClientFailure.unknown('Erro inesperado ao buscar clientes');
    }
  }

  @override
  Future<ClientModel> registerClient(ClientModel client) async {
    try {
      if (client.userId.isEmpty || client.name.isEmpty || client.phone.isEmpty) {
        throw ClientFailure.validation(
          'Nome, telefone ou usuário não podem estar vazios',
        );
      }

      // Gera ID automático
      final docRef = _firestore.collection('clients').doc();

      // Cria cópia do cliente com o ID gerado
      final clientToSave = client.copyWith(id: docRef.id);

      // Salva no Firestore
      await docRef.set(clientToSave.toMap());

      return clientToSave;
    } on FirebaseException catch (e) {
      throw ClientFailure.firebase('Erro ao registrar cliente: ${e.message}');
    } catch (e) {
      throw ClientFailure.unknown('Erro inesperado ao cadastrar cliente');
    }
  }

  @override
Future<void> updateClient(ClientModel client) async {
  try {
    if (client.id.isEmpty) {
      throw ClientFailure.validation('ID do cliente é obrigatório para atualização');
    }

    await _firestore
        .collection('clients')
        .doc(client.id)
        .update(client.toMap());
  } on FirebaseException catch (e) {
    throw ClientFailure.firebase('Erro ao atualizar cliente: ${e.message}');
  } catch (e) {
    throw ClientFailure.unknown('Erro inesperado ao atualizar cliente');
  }
}
}
