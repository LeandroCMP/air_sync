import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<InventoryItemModel>> getItems(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        return InventoryItemModel.fromMap(doc.id, doc.data());
      }).toList();
    } on FirebaseException catch (e) {
      throw InventoryFailure.firebase('Erro ao buscar itens: ${e.message}');
    } catch (e) {
      throw InventoryFailure.unknown('Erro inesperado ao buscar itens do estoque');
    }
  }

  @override
  Future<InventoryItemModel> registerItem(InventoryItemModel item) async {
    try {
      if (item.userId.isEmpty || item.description.isEmpty || item.unit.isEmpty || item.quantity <= 0) {
        throw InventoryFailure.validation(
          'Descrição, unidade, quantidade e usuário são obrigatórios',
        );
      }

      // Gera ID automático
      final docRef = _firestore.collection('inventory').doc();

      // Cria cópia do cliente com o ID gerado
      final itemToSave = item.copyWith(id: docRef.id);

      // Salva no Firestore
      await docRef.set(itemToSave.toMap());

      return itemToSave;
    } on FirebaseException catch (e) {
      throw InventoryFailure.firebase('Erro ao registrar item: ${e.message}');
    } catch (e) {
      throw InventoryFailure.unknown('Erro inesperado ao cadastrar item');
    }
  }

  @override
  Future<void> updateItem(InventoryItemModel item) async {
    try {
      if (item.id.isEmpty) {
        throw InventoryFailure.validation('ID do item é obrigatório para atualização');
      }

      await _firestore
          .collection('inventory')
          .doc(item.id)
          .update(item.toMap());
    } on FirebaseException catch (e) {
      throw InventoryFailure.firebase('Erro ao atualizar item: ${e.message}');
    } catch (e) {
      throw InventoryFailure.unknown('Erro inesperado ao atualizar item');
    }
  }

  @override
Future<void> addRecord({
  required String itemId,
  required double quantityToAdd,
}) async {
  try {
    final itemRef = _firestore.collection('inventory').doc(itemId);

    final record = {
      'date': DateTime.now().toIso8601String(),
      'quantityAdded': quantityToAdd,
    };

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(itemRef);
      if (!snapshot.exists) {
        throw InventoryFailure.validation('Item não encontrado');
      }

      final currentData = snapshot.data()!;
      final currentQuantity = (currentData['quantity'] ?? 0).toDouble();

      transaction.update(itemRef, {
        'quantity': currentQuantity + quantityToAdd,
        'entries': FieldValue.arrayUnion([record]),
      });
    });
  } on FirebaseException catch (e) {
    throw InventoryFailure.firebase('Erro ao adicionar registro: ${e.message}');
  } catch (e) {
    throw InventoryFailure.unknown('Erro inesperado ao registrar entrada');
  }
}

}
