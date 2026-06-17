import '../entities/user.dart';

abstract class AuthRepository {
  /// Send OTP to the phone number for the given role.
  /// Returns success message or throws exception on failure.
  Future<void> sendOtp({
    required String phone,
    required String role,
  });

  /// Verify OTP and create a session.
  /// Returns the authenticated user.
  Future<User> verifyOtp({
    required String phone,
    required String otpCode,
    required String role,
  });

  /// Login with username and password.
  /// Returns the authenticated user.
  Future<User> login({
    required String username,
    required String password,
  });

  /// Get the currently authenticated user from local storage.
  Future<User?> getCurrentUser();

  /// Clear the current session and user data.
  Future<void> logout();

  /// Check if a session exists and is valid.
  Future<bool> isSessionValid();
}
