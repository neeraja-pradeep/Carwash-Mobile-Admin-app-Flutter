import '../../domain/entities/job.dart';

sealed class ClaimJobState {
  const ClaimJobState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(Job) success,
    required T Function(String) error,
  }) {
    return switch (this) {
      ClaimJobInitial() => initial(),
      ClaimJobLoading() => loading(),
      ClaimJobSuccess s => success(s.job),
      ClaimJobError e => error(e.message),
    };
  }
}

class ClaimJobInitial extends ClaimJobState {
  const ClaimJobInitial();
}

class ClaimJobLoading extends ClaimJobState {
  const ClaimJobLoading();
}

class ClaimJobSuccess extends ClaimJobState {
  final Job job;
  final String jobType; // 'carwash' or 'driver_hire'

  const ClaimJobSuccess({
    required this.job,
    required this.jobType,
  });
}

class ClaimJobError extends ClaimJobState {
  final String message;

  const ClaimJobError({required this.message});
}
