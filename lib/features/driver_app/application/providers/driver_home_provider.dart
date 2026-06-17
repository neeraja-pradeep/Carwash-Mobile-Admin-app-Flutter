import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/driver_home_repository.dart';
import '../../infrastructure/repositories/driver_home_repository_impl.dart';
import '../states/driver_home_state.dart';

final driverHomeRepositoryProvider = Provider<DriverHomeRepository>((ref) {
  return DriverHomeRepositoryImpl();
});

final driverHomeStateProvider =
    StateNotifierProvider<DriverHomeNotifier, DriverHomeState>((ref) {
  final repository = ref.watch(driverHomeRepositoryProvider);
  return DriverHomeNotifier(repository);
});

class DriverHomeNotifier extends StateNotifier<DriverHomeState> {
  final DriverHomeRepository _repository;

  DriverHomeNotifier(this._repository) : super(const DriverHomeInitial());

  /// Load all home data (availability, stats, jobs)
  Future<void> loadHomeData() async {
    state = const DriverHomeLoading();
    try {
      final availability = await _repository.getAvailability();
      final stats = await _repository.getStats();
      final jobFeed = await _repository.getJobFeed();

      state = DriverHomeSuccess(
        availability: availability,
        stats: stats,
        jobFeed: jobFeed,
      );
    } catch (e) {
      state = DriverHomeError(message: e.toString());
    }
  }

  /// Toggle online/offline status (throws on error, doesn't modify state)
  Future<void> toggleAvailability({required bool online}) async {
    try {
      await _repository.setAvailability(online: online);
      // Reload home data after availability change succeeds
      await loadHomeData();
    } catch (e) {
      // Don't modify state on error, let caller handle it
      rethrow;
    }
  }

  /// Refresh stats for a specific period
  Future<void> refreshStats({
    String? period = 'today',
    String? start,
    String? end,
  }) async {
    try {
      final stats = await _repository.getStats(
        period: period,
        start: start,
        end: end,
      );

      if (state is DriverHomeSuccess) {
        final success = state as DriverHomeSuccess;
        state = DriverHomeSuccess(
          availability: success.availability,
          stats: stats,
          jobFeed: success.jobFeed,
        );
      }
    } catch (e) {
      state = DriverHomeError(message: e.toString());
    }
  }

  /// Refresh job feed for a specific date
  Future<void> refreshJobFeed({String? date}) async {
    try {
      final jobFeed = await _repository.getJobFeed(date: date);

      if (state is DriverHomeSuccess) {
        final success = state as DriverHomeSuccess;
        state = DriverHomeSuccess(
          availability: success.availability,
          stats: success.stats,
          jobFeed: jobFeed,
        );
      }
    } catch (e) {
      state = DriverHomeError(message: e.toString());
    }
  }
}
