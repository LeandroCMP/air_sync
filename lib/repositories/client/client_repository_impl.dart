import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/application/core/errors/client_failure.dart';
import 'client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final AuthServiceApplication _authServiceApplication;

  ClientRepositoryImpl({required AuthServiceApplication authServiceApplication})
  : _authServiceApplication = authServiceApplication;

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
  Future<void> registerClient(ClientModel client) async {
    try {
      if (client.userId.isEmpty ||
          client.name.isEmpty ||
          client.phone.isEmpty) {
        throw ClientFailure.validation(
          'Nome, telefone ou usuário não podem estar vazios',
        );
      }

      final docRef = _firestore.collection('clients').doc();
      final clientToSave = client.copyWith(id: docRef.id);

      await docRef.set(clientToSave.toMap());
    } on FirebaseException catch (e) {
      throw ClientFailure.firebase('Erro ao registrar cliente: ${e.message}');
    } catch (e) {
      throw ClientFailure.unknown('Erro inesperado ao cadastrar cliente');
    }
  }
}
