import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Each use case is a single-purpose, testable unit of business logic that
/// mediates between presentation and [AuthRepository]. They're trivial
/// delegations today, but this is the seam where future rules (e.g.
/// "require email verification before sign-in", analytics events, rate
/// limiting) get added without touching the repository or the UI.
class SignInWithEmail {
  const SignInWithEmail(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    required String username,
  }) {
    return _repository.signUpWithEmail(email: email, password: password, username: username);
  }
}

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signInWithGoogle();
}

class SignInWithApple {
  const SignInWithApple(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signInWithApple();
}

class SendPasswordResetEmail {
  const SendPasswordResetEmail(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call(String email) => _repository.sendPasswordResetEmail(email);
}

class UpdatePassword {
  const UpdatePassword(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call(String newPassword) => _repository.updatePassword(newPassword);
}

class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
