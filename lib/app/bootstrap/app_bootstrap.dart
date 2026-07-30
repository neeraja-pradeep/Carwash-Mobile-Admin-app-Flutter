import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/monitoring/sentry_config.dart';
import '../app.dart';

/// Starts the app: ensures bindings, then mounts the root [ProviderScope].
///
/// Initializes:
/// - Flutter bindings
/// - Environment variables (.env) — optional
/// - Sentry crash reporting, which wraps the rest of startup so anything that
///   throws from here on reaches the issue stream
/// - Hive for local storage
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (optional with fallback).
  // Runs before Sentry so a per-machine SENTRY_DSN override is picked up.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found — API will use default fallback URL
    // If you see API errors, ensure .env file exists in project root
  }

  await SentryFlutter.init(SentryConfig.apply, appRunner: _startApp);
}

/// The real startup body — called by Sentry from inside its error-capturing
/// zone, which is why Hive init and `runApp` live here rather than above.
Future<void> _startApp() async {
  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: DriveDeckApp()));
}
