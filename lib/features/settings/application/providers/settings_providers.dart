import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/data_sources/local/settings_local_ds.dart';
import '../../infrastructure/repositories/settings_repository_impl.dart';

/// Local data source (swapped for remote+cache in API phase).
final settingsLocalDsProvider = Provider<SettingsLocalDs>(
  (ref) => const SettingsLocalDs(),
);

/// The settings repository (domain contract → infrastructure impl).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDsProvider)),
);

/// All settings (read). Kept alive so navigation back is instant.
final appSettingsProvider = FutureProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).fetchSettings(),
);
