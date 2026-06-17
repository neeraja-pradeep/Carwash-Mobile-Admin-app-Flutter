import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call({
    required String username,
    required String password,
  }) {
    return repository.login(username: username, password: password);
  }
}
