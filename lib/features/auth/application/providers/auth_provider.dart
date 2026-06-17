import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      state = AuthSuccess(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(
        username: username,
        password: password,
      );
      state = AuthSuccess(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthInitial();
  }

  Future<void> checkCurrentSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthSuccess(user: user);
      } else {
        state = const AuthInitial();
      }
    } catch (e) {
      state = const AuthInitial();
    }
  }
}
