import '../../../../core/auth/session.dart';
import '../../../../core/auth/session_manager.dart';

class GetSessionUseCase {
  GetSessionUseCase(this._sessionManager);

  final SessionManager _sessionManager;

  Session? call() => _sessionManager.session;
}
