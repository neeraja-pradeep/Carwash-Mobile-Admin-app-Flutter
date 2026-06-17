import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<User> call({
    required String phone,
    required String otpCode,
    required String role,
  }) {
    return repository.verifyOtp(
      phone: phone,
      otpCode: otpCode,
      role: role,
    );
  }
}
