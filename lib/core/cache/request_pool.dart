import 'dart:async';

/// Request-deduplication pool (per `docs/HIVE implementation.md`).
///
/// Ensures two simultaneous calls to the same cache key make only ONE network
/// request — both callers receive the same [Future]. Wired into the repository
/// layer in the API-integration phase.
class RequestPool {
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Runs [request] for [key], or returns the in-flight future if one exists.
  Future<T> dedupe<T>(String key, Future<T> Function() request) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);

    final future = request();
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  bool isInFlight(String key) => _inFlight.containsKey(key);
}
