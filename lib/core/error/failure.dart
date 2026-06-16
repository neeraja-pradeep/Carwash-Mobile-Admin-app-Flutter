/// Domain-level failure model. Every feature maps API/Hive/parse errors onto a
/// [Failure] so the presentation layer can render a consistent error state.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// No connectivity / request could not reach the server.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet. Please retry.']);
}

/// Server returned an error (5xx / unexpected status).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Retry.']);
}

/// Response could not be parsed / validated.
class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Unable to load data.']);
}

/// Local cache (Hive) read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error.']);
}

/// Input validation failure (shown inline below a field).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
