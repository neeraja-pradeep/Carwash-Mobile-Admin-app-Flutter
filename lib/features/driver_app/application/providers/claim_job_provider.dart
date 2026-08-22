import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../infrastructure/repositories/schedule_repository_impl.dart';
import '../states/claim_job_state.dart';

final claimJobRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

final claimJobStateProvider =
    StateNotifierProvider<ClaimJobNotifier, ClaimJobState>((ref) {
  final repository = ref.watch(claimJobRepositoryProvider);
  return ClaimJobNotifier(repository);
});

class ClaimJobNotifier extends StateNotifier<ClaimJobState> {
  final ScheduleRepository _repository;

  ClaimJobNotifier(this._repository) : super(const ClaimJobInitial());

  /// Claim a carwash job
  Future<void> claimCarwashJob(String bookingId) async {
    state = const ClaimJobLoading();
    try {
      final job = await _repository.claimCarwashJob(bookingId);
      state = ClaimJobSuccess(job: job, jobType: 'carwash');
    } catch (e) {
      state = ClaimJobError(message: e.toString());
      rethrow;
    }
  }

  /// Claim a driver-hire/inspection job
  Future<void> claimDriverHireJob(String bookingId) async {
    state = const ClaimJobLoading();
    try {
      final job = await _repository.claimDriverHireJob(bookingId);
      state = ClaimJobSuccess(job: job, jobType: 'driver_hire');
    } catch (e) {
      state = ClaimJobError(message: e.toString());
      rethrow;
    }
  }

  /// Reset state
  void reset() {
    state = const ClaimJobInitial();
  }
}
