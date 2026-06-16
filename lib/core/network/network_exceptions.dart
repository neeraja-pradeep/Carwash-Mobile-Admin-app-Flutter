/// Network error types used by the retry policy and (in the API phase) the
/// repository error mapping.
sealed class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// An HTTP response with a non-success status code.
class HttpStatusException extends NetworkException {
  const HttpStatusException(this.statusCode, [String message = 'HTTP error'])
      : super(message);

  final int statusCode;

  /// 4xx — client errors must NOT be retried.
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// 5xx — server errors are retryable.
  bool get isServerError => statusCode >= 500;
}

/// No connectivity / request could not reach the server.
class ConnectionException extends NetworkException {
  const ConnectionException([super.message = 'No connection']);
}

/// Request exceeded the configured timeout.
class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException([super.message = 'Request timed out']);
}
