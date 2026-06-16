import '../entities/app_settings.dart';

/// Contract for reading and updating application settings.
///
/// In the static prototype only `fetchSettings` is needed; mutation methods
/// (saveHiringRates, toggleNotification, etc.) will be wired to an API in a
/// later phase.
abstract class SettingsRepository {
  Future<AppSettings> fetchSettings();
}
