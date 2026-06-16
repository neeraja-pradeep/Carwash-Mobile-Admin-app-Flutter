import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Unified logging wrapper. Routes through `dart:developer` in debug and is a
/// no-op in release, so logs never leak in production builds. Never log tokens,
/// passwords, OTPs or other sensitive values.
class AppLogger {
  const AppLogger._();

  static void debug(String message, {String name = 'DriveDeck'}) {
    if (kDebugMode) developer.log(message, name: name);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'DriveDeck',
  }) {
    if (kDebugMode) {
      developer.log(message, name: name, error: error, stackTrace: stackTrace);
    }
  }
}
