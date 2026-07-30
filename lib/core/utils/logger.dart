import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../monitoring/error_reporter.dart';

/// Unified logging wrapper. Routes through `dart:developer` in debug and is a
/// no-op in release, so logs never leak in production builds. Never log tokens,
/// passwords, OTPs or other sensitive values.
class AppLogger {
  const AppLogger._();

  static void debug(String message, {String name = 'DriveDeck'}) {
    if (kDebugMode) developer.log(message, name: name);
  }

  /// Logs a handled error locally and forwards it to Sentry.
  ///
  /// Unlike [debug] this reports in every build mode — a caught-and-degraded
  /// failure in production is exactly what we want on the dashboard. Pass
  /// [report] as `false` for expected, noisy failures that shouldn't open an
  /// issue.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'DriveDeck',
    bool report = true,
  }) {
    if (kDebugMode) {
      developer.log(message, name: name, error: error, stackTrace: stackTrace);
    }
    if (report && error != null) {
      // Fire-and-forget: the SDK queues and sends off the caller's path.
      ErrorReporter.report(error, stackTrace: stackTrace, message: message);
    }
  }
}
