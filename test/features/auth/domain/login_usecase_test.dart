import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:air_sync/core/auth/session.dart';
import 'package:air_sync/core/errors/failures.dart';
import 'package:air_sync/features/auth/domain/repositories/auth_repository.dart';
import 'package:air_sync/features/auth/domain/usecases/login_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  test('should call repository login with correct params', () async {
    const session = Session(
      userId: '1',
      email: 'admin@demo.local',
      name: 'Admin',
      permissions: ['orders.read'],
      tenantId: 'tenant',
      accessToken: 'token',
      refreshToken: 'refresh',
      jti: 'jti',
    );
    when(() => repository.login(any(), any(), tenantId: any(named: 'tenantId'))).thenAnswer((_) async => const Right(session));

    final result = await useCase(LoginParams(email: 'e', password: 'p', tenantId: 'tenant'));

    expect(result.isRight(), true);
    verify(() => repository.login('e', 'p', tenantId: 'tenant')).called(1);
  });

  test('should propagate failure', () async {
    when(() => repository.login(any(), any(), tenantId: any(named: 'tenantId')))
        .thenAnswer((_) async => const Left(UnauthorizedFailure('erro')));

    final result = await useCase(LoginParams(email: 'e', password: 'p'));

    expect(result.isLeft(), true);
  });
}
