import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/session.dart';

class AuthLocalDataSource {
  static const String _userBoxName = 'auth_users';
  static const String _sessionBoxName = 'auth_sessions';
  static const String _currentUserKey = 'current_user';
  static const String _currentSessionKey = 'current_session';

  /// Save user to local storage.
  Future<void> saveUser(User user) async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_userBoxName);
    await box.put(_currentUserKey, user.toJson());
  }

  /// Get current user from local storage.
  Future<User?> getCurrentUser() async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>(_userBoxName);
      final userJson = box.get(_currentUserKey);
      if (userJson != null) {
        return User.fromJson(Map<String, dynamic>.from(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save session to local storage.
  Future<void> saveSession(Session session) async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_sessionBoxName);
    await box.put(_currentSessionKey, {
      'sessionId': session.sessionId,
      'csrfToken': session.csrfToken,
      'expiresAt': session.expiresAt.toIso8601String(),
    });
  }

  /// Get session from local storage.
  Future<Session?> getSession() async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>(_sessionBoxName);
      final sessionData = box.get(_currentSessionKey);
      if (sessionData != null) {
        return Session(
          sessionId: sessionData['sessionId'],
          csrfToken: sessionData['csrfToken'],
          expiresAt: DateTime.parse(sessionData['expiresAt']),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all auth data from local storage.
  Future<void> clearAuthData() async {
    try {
      final userBox = await Hive.openBox<Map<dynamic, dynamic>>(_userBoxName);
      await userBox.delete(_currentUserKey);

      final sessionBox = await Hive.openBox<Map<dynamic, dynamic>>(_sessionBoxName);
      await sessionBox.delete(_currentSessionKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
