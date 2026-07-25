import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ironcoach/core/error/failures.dart';
import 'package:ironcoach/features/auth/domain/entities/app_user.dart';
import 'package:ironcoach/features/auth/domain/repositories/auth_repository.dart';
import 'package:ironcoach/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInWithEmail useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SignInWithEmail(repository);
  });

  const user =
      AppUser(id: 'u1', email: 'test@ironcoach.app', emailConfirmed: true);

  test('delegates to the repository and returns its success result', () async {
    when(() => repository.signInWithEmail(
            email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Right(user));

    final result =
        await useCase(email: 'test@ironcoach.app', password: 'password123');

    expect(result, const Right<Failure, AppUser>(user));
    verify(() => repository.signInWithEmail(
        email: 'test@ironcoach.app', password: 'password123')).called(1);
  });

  test('propagates a failure from the repository unchanged', () async {
    const failure = Failure.unauthorized('Invalid credentials');
    when(() => repository.signInWithEmail(
            email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Left(failure));

    final result =
        await useCase(email: 'test@ironcoach.app', password: 'wrong');

    expect(result, const Left<Failure, AppUser>(failure));
  });
}
