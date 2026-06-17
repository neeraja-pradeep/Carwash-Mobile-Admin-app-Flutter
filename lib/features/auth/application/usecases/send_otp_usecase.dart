import '../../domain/repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<void> call({
    required String phone,
    required String role,
  }) {
    return repository.sendOtp(phone: phone, role: role);
  }
}
