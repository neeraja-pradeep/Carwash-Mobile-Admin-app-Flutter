import 'dart:async';
import 'dart:math';

import '../network/network_exceptions.dart';
import 'cache_config.dart';

/// Exponential-backoff retry strategy (per `docs/HIVE implementation.md`).
///
/// Delay = `pow(2, attempt - 1) * 2` seconds (+2s / +4s / +8s); max 4 attempts.
/// 4xx [HttpStatusException]s are re-thrown immediately (never retried).
class RetryPolicy {
  const RetryPolicy();

  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = CacheConfig.maxRetryAttempts,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        if (error is HttpStatusException && error.isClientError) rethrow;
        if (attempt >= maxAttempts) rethrow;
        final seconds = pow(2, attempt - 1).toInt() * 2;
        await Future<void>.delayed(Duration(seconds: seconds));
      }
    }
  }
}
