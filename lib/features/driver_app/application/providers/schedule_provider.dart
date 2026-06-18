import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../infrastructure/repositories/schedule_repository_impl.dart';
import '../states/schedule_state.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

final scheduleStateProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleNotifier(repository);
});

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository) : super(const ScheduleInitial());

  /// Load schedule with upcoming and completed jobs
  Future<void> loadSchedule({
    String? from,
    String? to,
    int page = 1,
    int pageSize = 10,
  }) async {
    state = const ScheduleLoading();
    try {
      final schedule = await _repository.getSchedule(
        from: from,
        to: to,
        page: page,
        pageSize: pageSize,
      );
      state = ScheduleSuccess(schedule: schedule, currentPage: page);
    } catch (e) {
      state = ScheduleError(message: e.toString());
    }
  }

  /// Load next page of completed jobs
  Future<void> loadNextPage({
    String? from,
    String? to,
    int pageSize = 10,
  }) async {
    if (state is! ScheduleSuccess) return;
    final success = state as ScheduleSuccess;
    final nextPage = success.currentPage + 1;

    state = ScheduleSuccess(
      schedule: success.schedule,
      currentPage: success.currentPage,
      isLoadingMore: true,
    );

    try {
      final schedule = await _repository.getSchedule(
        from: from,
        to: to,
        page: nextPage,
        pageSize: pageSize,
      );
      state = ScheduleSuccess(
        schedule: schedule,
        currentPage: nextPage,
      );
    } catch (e) {
      state = ScheduleSuccess(
        schedule: success.schedule,
        currentPage: success.currentPage,
      );
      rethrow;
    }
  }
}
