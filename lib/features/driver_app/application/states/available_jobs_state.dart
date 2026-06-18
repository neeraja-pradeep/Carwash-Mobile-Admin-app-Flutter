import '../../domain/entities/job.dart';

sealed class AvailableJobsState {
  const AvailableJobsState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(AvailableJobsSuccess) success,
    required T Function(AvailableJobsError) error,
  }) {
    return switch (this) {
      AvailableJobsInitial() => initial(),
      AvailableJobsLoading() => loading(),
      AvailableJobsSuccess s => success(s),
      AvailableJobsError e => error(e),
    };
  }
}

class AvailableJobsInitial extends AvailableJobsState {
  const AvailableJobsInitial();
}

class AvailableJobsLoading extends AvailableJobsState {
  const AvailableJobsLoading();
}

class AvailableJobsSuccess extends AvailableJobsState {
  final List<Job> jobs;
  final int count;
  final String? nextPageUrl;
  final int currentPage;
  final bool isLoadingMore;

  const AvailableJobsSuccess({
    required this.jobs,
    required this.count,
    this.nextPageUrl,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });
}

class AvailableJobsError extends AvailableJobsState {
  final String message;

  const AvailableJobsError({required this.message});
}
