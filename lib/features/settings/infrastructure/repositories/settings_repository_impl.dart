import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/local/settings_local_ds.dart';

/// Concrete implementation that delegates to [SettingsLocalDs].
///
/// Swapped for a remote+cache implementation in the API phase without
/// touching providers or UI.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._ds);

  final SettingsLocalDs _ds;

  @override
  Future<AppSettings> fetchSettings() => _ds.fetchSettings();
}
