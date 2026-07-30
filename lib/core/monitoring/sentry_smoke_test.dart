import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_config.dart';

/// Error type raised by the in-app Sentry verification actions.
///
/// Distinct from every real failure in the app so these events are trivial to
/// spot — and to filter out — in the issue stream.
class SentryVerificationException implements Exception {
  const SentryVerificationException(this.message);

  final String message;

  @override
  String toString() => 'SentryVerificationException: $message';
}

/// Reports a *handled* verification error and returns the Sentry event id, or
/// `null` when reporting is disabled or the event was dropped.
///
/// Use this to confirm the DSN, network path and release/environment tags are
/// right without actually taking the app down.
Future<String?> sendSentryTestEvent() async {
  if (!SentryConfig.isEnabled) return null;
  final id = await Sentry.captureException(
    const SentryVerificationException(
      'Manual test event from Drivey Admin settings',
    ),
    stackTrace: StackTrace.current,
    withScope: (scope) => scope.setTag('verification', 'manual'),
  );
  return id == SentryId.empty() ? null : id.toString();
}

/// Throws an *unhandled* error to verify the crash path — the zone/Flutter
/// error integrations installed by `SentryFlutter.init` should pick this up
/// with no `try`/`catch` anywhere in between.
Never throwSentryTestCrash() {
  throw const SentryVerificationException(
    'Manual test crash from Drivey Admin settings',
  );
}
