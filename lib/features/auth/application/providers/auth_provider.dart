import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_session_signal.dart';
import '../../../../core/monitoring/error_reporter.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';
import '../states/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

/// Check if user is already authenticated on app startup
final checkAuthStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final repository = ref.watch(authRepositoryProvider);
    final isValid = await repository.isSessionValid();
    if (isValid) {
      final user = await repository.getCurrentUser();
      if (user != null) {
        // Restore the session
        ref.read(authStateProvider.notifier).checkCurrentSession();
        return true;
      }
    }
    return false;
  } catch (e) {
    return false;
  }
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(const AuthInitial());

  Future<void> sendOtp({
    required String phone,
    required String role,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.sendOtp(phone: phone, role: role);
      state = OtpSent(phone: phone, role: role);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otpCode,
    required String role,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.verifyOtp(
        phone: phone,
        otpCode: otpCode,
        role: role,
      );
      _identify(user);
      state = AuthSuccess(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> login({
    required String username,
    required String password,
    bool validateAdminRole = true,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(
        username: username,
        password: password,
      );

      // Validate role for admin console - only admin and superadmin are allowed
      if (validateAdminRole &&
          user.role != 'admin' &&
          user.role != 'superadmin') {
        await _repository.logout();
        state = AuthError(
          message:
              'Access denied. Only admins and superadmins can access this console.',
        );
        return;
      }

      _identify(user);
      state = AuthSuccess(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    ErrorReporter.clearOperator();
    AuthSessionSignal.instance.markSignedOut();
    state = const AuthInitial();
  }

  /// The server rejected the session while the app was in use (see the 401
  /// interceptor). Drops the cached user/session so the next launch starts at
  /// login instead of restoring a session the server no longer honours. No
  /// logout call — the session is already gone server-side.
  Future<void> handleSessionExpired() async {
    await _repository.clearLocalSession();
    ErrorReporter.clearOperator();
    state = const AuthInitial();
  }

  /// Attaches the signed-in operator to crash reports so an issue can be traced
  /// back to the account that hit it, and opens the router's auth gate.
  void _identify(User user) {
    ErrorReporter.setOperator(
      id: user.id.toString(),
      username: user.username,
      role: user.role,
    );
    AuthSessionSignal.instance.markAuthenticated();
  }

  /// Check if user has valid session on app startup
  Future<void> checkCurrentSession() async {
    try {
      final isValid = await _repository.isSessionValid();
      if (isValid) {
        final user = await _repository.getCurrentUser();
        if (user != null) {
          _identify(user);
          state = AuthSuccess(user: user);
          return;
        }
      }
      _markNoSession();
    } catch (e) {
      _markNoSession();
    }
  }

  /// Closes the router's auth gate after a failed session restore, without
  /// clearing an expiry notice the 401 interceptor may have just raised.
  void _markNoSession() {
    if (!AuthSessionSignal.instance.wasExpired) {
      AuthSessionSignal.instance.markSignedOut();
    }
    state = const AuthInitial();
  }
}
