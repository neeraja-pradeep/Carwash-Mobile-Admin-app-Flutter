import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../infrastructure/repositories/schedule_repository_impl.dart';
import '../states/available_jobs_state.dart';

final availableJobsRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

final availableJobsStateProvider =
    StateNotifierProvider<AvailableJobsNotifier, AvailableJobsState>((ref) {
  final repository = ref.watch(availableJobsRepositoryProvider);
  return AvailableJobsNotifier(repository);
});

class AvailableJobsNotifier extends StateNotifier<AvailableJobsState> {
  final ScheduleRepository _repository;

  AvailableJobsNotifier(this._repository) : super(const AvailableJobsInitial());

  /// Load available/claimable jobs
  Future<void> loadAvailableJobs({
    int page = 1,
    int pageSize = 10,
  }) async {
    state = const AvailableJobsLoading();
    try {
      final jobs = await _repository.getAvailableJobs(
        page: page,
        pageSize: pageSize,
      );
      // TODO: Get pagination info from API response
      state = AvailableJobsSuccess(
        jobs: jobs,
        count: jobs.length,
        currentPage: page,
      );
    } catch (e) {
      state = AvailableJobsError(message: e.toString());
    }
  }

  /// Load next page of available jobs
  Future<void> loadNextPage({
    int pageSize = 10,
  }) async {
    if (state is! AvailableJobsSuccess) return;
    final success = state as AvailableJobsSuccess;
    final nextPage = success.currentPage + 1;

    state = AvailableJobsSuccess(
      jobs: success.jobs,
      count: success.count,
      nextPageUrl: success.nextPageUrl,
      currentPage: success.currentPage,
      isLoadingMore: true,
    );

    try {
      final jobs = await _repository.getAvailableJobs(
        page: nextPage,
        pageSize: pageSize,
      );
      state = AvailableJobsSuccess(
        jobs: [...success.jobs, ...jobs],
        count: success.count,
        currentPage: nextPage,
      );
    } catch (e) {
      state = AvailableJobsSuccess(
        jobs: success.jobs,
        count: success.count,
        nextPageUrl: success.nextPageUrl,
        currentPage: success.currentPage,
      );
      rethrow;
    }
  }
}
