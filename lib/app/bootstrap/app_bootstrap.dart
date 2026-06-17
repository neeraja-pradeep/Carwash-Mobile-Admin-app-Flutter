import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app.dart';

/// Starts the app: ensures bindings, then mounts the root [ProviderScope].
///
/// Initializes:
/// - Flutter bindings
/// - Environment variables (.env) — optional
/// - Hive for local storage
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (optional with fallback)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found — API will use default fallback URL
    // If you see API errors, ensure .env file exists in project root
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: DriveDeckApp()));
}
