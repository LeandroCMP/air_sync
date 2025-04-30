import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/repositories/auth/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Future<UserModel> auth(String email, String password) async {
    try {
      // Autentica o usuário com e-mail e senha
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      // Verifica se o FirebaseAuth retornou um usuário válido
      if (user == null) {
        throw const AuthFailure(
          AuthFailureType.userNotFound,
          'Usuário autenticado é inválido.',
        );
      }

      // Busca os dados do Firestore vinculados ao UID do usuário autenticado
      final snapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw const AuthFailure(
          AuthFailureType.userNotFound,
          'Usuário não encontrado no Firestore.',
        );
      }

      // Constrói e retorna o modelo do usuário combinando Auth e Firestore
      return UserModel.fromMap(snapshot.data()!, user.uid, user.email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromException(e);
    } on FirebaseException {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Erro ao acessar o Firebase. Verifique sua conexão.',
      );
    } catch (_) {
      throw const AuthFailure(AuthFailureType.unknown, 'Erro inesperado.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromException(e);
    } catch (_) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Erro ao enviar e-mail de redefinição de senha. Tente novamente.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromException(e);
    } catch (_) {
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Erro ao realizar logout. Tente novamente.',
      );
    }
  }
}
