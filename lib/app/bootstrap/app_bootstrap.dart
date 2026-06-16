import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';

/// Starts the app: ensures bindings, then mounts the root [ProviderScope].
///
/// Hive box opening / adapter registration is intentionally deferred to the
/// API-integration phase (see `hive_init.dart`); the UI runs entirely on the
/// in-memory static data sources today.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DriveDeckApp()));
}
