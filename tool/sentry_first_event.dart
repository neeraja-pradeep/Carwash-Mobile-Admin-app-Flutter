// Sends a real error event to the Drivey Admin Sentry project from a terminal,
// no device or emulator required.
//
//   dart run tool/sentry_first_event.dart
//   dart run tool/sentry_first_event.dart --dsn <other-dsn> --env staging
//
// Use it to activate a freshly created project (Sentry only leaves onboarding
// once it has received an event) or to check that a DSN/network path works
// before spending a build cycle on it. The app's own reporting is configured in
// lib/core/monitoring/sentry_config.dart — this script deliberately duplicates
// only the DSN so it can run outside the Flutter engine.

import 'dart:io';

import 'package:sentry/sentry.dart';

const String _defaultDsn =
    'https://b9bcdf17a72a19fc5ac78d3fecb41267@o4510509677608960.ingest.us.sentry.io/4511818928160768';

/// Mirrors `SentryVerificationException` in lib/core/monitoring so events from
/// the script and from the in-app trigger group together in the issue stream.
class SentryVerificationException implements Exception {
  const SentryVerificationException(this.message);

  final String message;

  @override
  String toString() => 'SentryVerificationException: $message';
}

Future<void> main(List<String> args) async {
  final dsn = _flag(args, '--dsn') ?? _defaultDsn;
  final environment = _flag(args, '--env') ?? 'debug';

  await Sentry.init((options) {
    options.dsn = dsn;
    options.environment = environment;
    options.release = 'drivey-admin@tooling';
    options.debug = true;
  });

  stdout.writeln('Sending verification event to $dsn ($environment)…');

  final id = await Sentry.captureException(
    const SentryVerificationException(
      'First event from tool/sentry_first_event.dart — Sentry integration check',
    ),
    stackTrace: StackTrace.current,
    withScope: (scope) => scope.setTag('verification', 'cli'),
  );

  // Flushes the queue and shuts the SDK down; without this the process can exit
  // before the transport has written the request.
  await Sentry.close();

  if (id == SentryId.empty()) {
    stderr.writeln('Event was dropped — check the DSN and network access.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Delivered. Event id: $id');
}

String? _flag(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
