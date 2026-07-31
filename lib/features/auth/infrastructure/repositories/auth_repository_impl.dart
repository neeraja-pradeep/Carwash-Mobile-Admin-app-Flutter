import '../../../../core/network/http_client.dart';
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
  Future<void> clearLocalSession() async {
    HttpClient.clearSessionId();
    await _localDataSource.clearAuthData();
  }

  @override
  Future<bool> isSessionValid() async {
    final session = await _localDataSource.getSession();
    if (session == null || session.isExpired) return false;

    // The stored expiry is client-side bookkeeping we invent at login — the
    // server can drop the session long before it lapses (signed out elsewhere,
    // server restart, password change). Trusting it alone let the app restore a
    // dead session and land on a dashboard where every call 401s.
    try {
      return await _authApi.validateSession();
    } catch (e) {
      // Transport failure, not a rejection — stay signed in so an offline
      // launch still works. The 401 interceptor bounces us if the session is
      // genuinely gone once the network is back.
      return true;
    }
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
