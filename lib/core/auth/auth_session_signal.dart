import 'package:flutter/foundation.dart';

/// App-wide answer to "may the router show a protected route right now?".
///
/// Deliberately lives outside Riverpod: the Dio 401 interceptor (core layer)
/// and the GoRouter `redirect` (app layer) both need it, and neither has a
/// provider container to read from. `AuthStateNotifier` is what keeps it in
/// sync with the real auth state — nothing else should flip it except the
/// interceptor, which is the one place that learns the server dropped us.
class AuthSessionSignal extends ChangeNotifier {
  AuthSessionSignal._();

  static final AuthSessionSignal instance = AuthSessionSignal._();

  bool _authenticated = false;
  bool _expired = false;

  /// True once a session exists — a fresh login, an OTP verify, or a stored
  /// session the server still accepts.
  bool get isAuthenticated => _authenticated;

  /// True when the last sign-out was the *server* rejecting the session rather
  /// than the operator tapping "Log out". The login screen uses it to explain
  /// why they were bounced.
  bool get wasExpired => _expired;

  void markAuthenticated() {
    final changed = !_authenticated || _expired;
    _authenticated = true;
    _expired = false;
    if (changed) notifyListeners();
  }

  /// Operator-initiated sign-out.
  void markSignedOut() => _clear(expired: false);

  /// The server rejected the session (401, or a DRF 403 "credentials were not
  /// provided"). Drives the bounce back to login from wherever we are.
  void markSessionExpired() => _clear(expired: true);

  /// Reads and clears [wasExpired] so the notice shows exactly once.
  bool consumeExpiredFlag() {
    if (!_expired) return false;
    _expired = false;
    return true;
  }

  void _clear({required bool expired}) {
    // Guard the notify: the interceptor can fire this once per in-flight
    // request when a whole screen's worth of calls 401 together.
    final changed = _authenticated || _expired != expired;
    _authenticated = false;
    _expired = expired;
    if (changed) notifyListeners();
  }
}
