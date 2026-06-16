import 'package:hive_flutter/hive_flutter.dart';

import '../../core/cache/cache_entry.dart';

/// Initialises Hive and registers adapters before any box is opened.
///
/// Deferred to the API-integration phase: the UI runs on in-memory static data
/// today, so [bootstrap] does NOT call this yet. When the cache is switched on,
/// call `await initHive()` from `bootstrap()` before `runApp`. Registering
/// adapters here (before any `openBox`) keeps Hive model integrity intact.
Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CacheEntryAdapter());
  }
}
