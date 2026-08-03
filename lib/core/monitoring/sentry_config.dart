import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry wiring — DSN resolution and the `SentryFlutter.init` options.
///
/// Resolution order for the DSN (first non-empty wins):
/// 1. `--dart-define=SENTRY_DSN=…` (per-build override, e.g. from CI)
/// 2. `SENTRY_DSN` in `.env` (per-developer override; `.env` is git-ignored)
/// 3. The compiled-in project DSN below
///
/// The DSN is not a secret — it is a write-only ingest endpoint that ships
/// inside every released binary — so keeping the default in source is safe and
/// means a fresh clone reports crashes without extra setup. Setting
/// `SENTRY_DSN=` (empty) in `.env` opts a machine out of reporting.
class SentryConfig {
  const SentryConfig._();

  /// Drivey Admin project (org `o4510509677608960`) on Sentry US.
  static const String _fallbackDsn =
      'https://fe79ad5742956e58792b1782dba7a089@o4510509677608960.ingest.us.sentry.io/4511847144751104';

  static const String _dsnFromDefine = String.fromEnvironment('SENTRY_DSN');

  /// The DSN this build reports to; empty disables the SDK.
  static String get dsn {
    if (_dsnFromDefine.isNotEmpty) return _dsnFromDefine;
    // `dotenv.env` throws when `.env` was never loaded, which bootstrap tolerates.
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['SENTRY_DSN'];
      if (fromEnv != null) return fromEnv.trim();
    }
    return _fallbackDsn;
  }

  /// Environment tag shown in the Sentry issue stream.
  static String get environment {
    const fromDefine = String.fromEnvironment('SENTRY_ENVIRONMENT');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kReleaseMode) return 'production';
    return kProfileMode ? 'profile' : 'debug';
  }

  /// Whether reporting is wired for this build. Callers use it to hide the
  /// in-app diagnostics affordances when the DSN has been blanked out.
  static bool get isEnabled => dsn.isNotEmpty;

  /// Applies the project's options. Passed to `SentryFlutter.init`.
  ///
  /// Release/dist are left unset so the SDK derives them from the platform
  /// package info (`1.0.0+1` from `pubspec.yaml`) and they never go stale.
  static void apply(SentryFlutterOptions options) {
    options.dsn = dsn;
    options.environment = environment;

    // Performance tracing: everything outside release so a dev build always has
    // traces to look at; 20% in production keeps the event quota sane.
    options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;

    // Ship a screenshot with crashes — text is masked by default, and it makes
    // UI-state bugs far easier to read than a stack trace alone.
    // (`attachViewHierarchy` is still marked experimental in the SDK, so it is
    // deliberately left off.)
    options.attachScreenshot = true;

    // The console handles customer PII, so never let the SDK attach IPs or
    // request bodies on its own. The only identity we send is the operator id
    // set explicitly in `ErrorReporter.setOperator`.
    options.sendDefaultPii = false;

    // Taps / navigation / HTTP breadcrumbs are on by default; keep a deeper
    // trail than the 100-crumb default because operator flows are long.
    options.maxBreadcrumbs = 150;

    // SDK's own diagnostics — useful while verifying the integration locally.
    options.debug = kDebugMode;
  }
}
