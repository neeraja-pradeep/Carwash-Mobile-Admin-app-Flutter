import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_config.dart';

/// Thin facade over Sentry so feature code never imports the SDK directly.
///
/// Everything here is a no-op when reporting is disabled (blank DSN) or the SDK
/// has not been initialised — safe to call from widget tests.
class ErrorReporter {
  const ErrorReporter._();

  /// Reports a handled error. Unhandled errors are captured automatically by
  /// the Flutter/zone integrations installed in `SentryFlutter.init`.
  static Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, String>? tags,
  }) async {
    if (!_active) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        tags?.forEach(scope.setTag);
        if (message != null) {
          scope.addBreadcrumb(
              Breadcrumb(message: message, level: SentryLevel.error));
        }
      },
    );
  }

  /// Records a navigation/action crumb that shows up on the next event's
  /// timeline. Cheap — kept in memory until something is actually reported.
  static Future<void> addBreadcrumb(String message, {String? category}) async {
    if (!_active) return;
    await Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, level: SentryLevel.info),
    );
  }

  /// Tags subsequent events with the signed-in operator. Call on login.
  ///
  /// Only the account id/username and role are sent — never phone, email or
  /// address — in line with `sendDefaultPii = false`.
  static Future<void> setOperator({
    required String id,
    String? username,
    String? role,
  }) async {
    if (!_active) return;
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, username: username));
      if (role != null) scope.setTag('role', role);
    });
  }

  /// Drops the operator identity. Call on logout.
  static Future<void> clearOperator() async {
    if (!_active) return;
    await Sentry.configureScope((scope) {
      scope.setUser(null);
      scope.removeTag('role');
    });
  }

  static bool get _active => SentryConfig.isEnabled && Sentry.isEnabled;
}
