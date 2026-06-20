import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_api.dart';
import '../data_sources/auth_local_ds.dart';
import '../models/auth_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi = AuthApi();
  final AuthLocalDataSource _localDataSource = AuthLocalDataSource();

  @override
  Future<void> sendOtp({
    required String phone,
    required String role,
  }) async {
    await _authApi.sendOtp(phone: phone, role: role);
  }

  @override
  Future<User> verifyOtp({
    required String phone,
    required String otpCode,
    required String role,
  }) async {
    final response = await _authApi.verifyOtp(
      phone: phone,
      otpCode: otpCode,
      role: role,
    );

    await _saveUserAndSession(response);
    return response.user;
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await _authApi.login(
      username: username,
      password: password,
    );

    await _saveUserAndSession(response);
    return response.user;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _localDataSource.getCurrentUser();
  }

  @override
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // If logout API fails, still clear local data
    }
    await _localDataSource.clearAuthData();
  }

  @override
  Future<bool> isSessionValid() async {
    final session = await _localDataSource.getSession();
    return session != null && !session.isExpired;
  }

  Future<void> _saveUserAndSession(AuthResponseModel response) async {
    await _localDataSource.saveUser(response.user);

    if (response.sessionId != null && response.csrfToken != null) {
      final session = Session(
        sessionId: response.sessionId!,
        csrfToken: response.csrfToken!,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      await _localDataSource.saveSession(session);
    }
  }
}
