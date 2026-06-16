/// Centralised cache tuning constants (per `docs/HIVE implementation.md`).
///
/// Wired into the 3-layer cache (L1 memory → L2 Hive → L3 network) in the
/// API-integration phase. Centralised here so thresholds are never hardcoded
/// across files.
class CacheConfig {
  const CacheConfig._();

  static const int memoryCacheMaxSize = 50 * 1024 * 1024; // 50MB
  static const int memoryCacheMaxEntries = 500;
  static const int hiveCacheMaxSize = 200 * 1024 * 1024; // 200MB
  static const Duration staleCacheThreshold = Duration(hours: 24);
  static const Duration validCacheThreshold = Duration(hours: 12);
  static const Duration apiTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 4;
  static const Duration retryBaseDelay = Duration(seconds: 2);
}
