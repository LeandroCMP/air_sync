import '../errors/exceptions.dart';
import 'failures.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is UnauthorizedException) {
    return const UnauthorizedFailure('Sessão expirada. Faça login novamente.');
  }
  if (error is ForbiddenException) {
    return const ForbiddenFailure('Você não tem permissão para acessar este recurso.');
  }
  if (error is NotFoundException) {
    return const NotFoundFailure('Recurso não encontrado.');
  }
  if (error is ConflictException) {
    return const ConflictFailure('Ação não pôde ser concluída por conflito.');
  }
  if (error is ValidationException) {
    return ValidationFailure('Dados inválidos: ${error.errors}');
  }
  if (error is CacheException) {
    return UnexpectedFailure('Não foi possível acessar o cache local.');
  }
  if (error is ServerException) {
    return UnexpectedFailure(error.message);
  }
  return const UnexpectedFailure('Ocorreu um erro inesperado.');
}
