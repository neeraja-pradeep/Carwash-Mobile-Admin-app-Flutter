import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/job_detail_repository.dart';
import '../../infrastructure/repositories/job_detail_repository_impl.dart';
import '../states/job_detail_state.dart';

final jobDetailRepositoryProvider = Provider<JobDetailRepository>((ref) {
  return JobDetailRepositoryImpl();
});

final jobDetailStateProvider = StateNotifierProvider.family<
    JobDetailNotifier,
    JobDetailState,
    String>((ref, jobId) {
  final repository = ref.watch(jobDetailRepositoryProvider);
  return JobDetailNotifier(repository, jobId);
});

class JobDetailNotifier extends StateNotifier<JobDetailState> {
  final JobDetailRepository _repository;
  final String _jobId;

  JobDetailNotifier(this._repository, this._jobId)
      : super(const JobDetailInitial());

  /// Load job detail from API
  Future<void> loadJobDetail() async {
    state = const JobDetailLoading();
    try {
      final job = await _repository.getJobDetail(_jobId);
      state = JobDetailSuccess(job: job);

      // Load bill if job is completed
      if (job.status == 'completed') {
        await loadBill();
      }
    } catch (e) {
      state = JobDetailError(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Mark arrived at job location
  Future<void> arrive() async {
    if (state is! JobDetailSuccess) return;
    final success = state as JobDetailSuccess;
    state = JobDetailSuccess(job: success.job, bill: success.bill, isLoading: true);

    try {
      final updatedJob = await _repository.arrive(_jobId);
      state = JobDetailSuccess(job: updatedJob, bill: success.bill);
    } catch (e) {
      state = JobDetailSuccess(job: success.job, bill: success.bill);
      rethrow;
    }
  }

  /// Verify start OTP and start the job
  Future<void> verifyStartOtp(String otp) async {
    if (state is! JobDetailSuccess) return;
    final success = state as JobDetailSuccess;
    state = JobDetailSuccess(job: success.job, bill: success.bill, isLoading: true);

    try {
      final updatedJob = await _repository.verifyStartOtp(_jobId, otp);
      state = JobDetailSuccess(job: updatedJob, bill: success.bill);
    } catch (e) {
      state = JobDetailSuccess(job: success.job, bill: success.bill);
      rethrow;
    }
  }

  /// Verify end OTP and end the job
  Future<void> verifyEndOtp(String otp) async {
    if (state is! JobDetailSuccess) return;
    final success = state as JobDetailSuccess;
    state = JobDetailSuccess(job: success.job, bill: success.bill, isLoading: true);

    try {
      final updatedJob = await _repository.verifyEndOtp(_jobId, otp);
      state = JobDetailSuccess(job: updatedJob, bill: success.bill);

      // Load bill after job is completed
      if (updatedJob.status == 'completed') {
        await loadBill();
      }
    } catch (e) {
      state = JobDetailSuccess(job: success.job, bill: success.bill);
      rethrow;
    }
  }

  /// Mark the outstanding balance as collected in cash.
  ///
  /// The API only accepts the exact `balance_due`, so the amount is taken from
  /// the job rather than entered by the driver.
  Future<void> collectCash() async {
    if (state is! JobDetailSuccess) return;
    final success = state as JobDetailSuccess;
    state = JobDetailSuccess(job: success.job, bill: success.bill, isLoading: true);

    try {
      final result = await _repository.collectCash(_jobId, success.job.balanceDue);
      state = JobDetailSuccess(
        job: success.job.copyWithSettlement(
          status: result.status,
          isPaid: result.isPaid,
          balanceDue: result.balanceDue,
          balancePaid: result.balancePaid,
          balancePaidAt: result.balancePaidAt,
        ),
        bill: success.bill,
      );

      // Refresh the bill so its own paid flags match the settled balance.
      await loadBill();
    } catch (e) {
      state = JobDetailSuccess(job: success.job, bill: success.bill);
      rethrow;
    }
  }

  /// Load final bill for completed job
  Future<void> loadBill() async {
    if (state is! JobDetailSuccess) return;
    final success = state as JobDetailSuccess;

    try {
      final bill = await _repository.getFinalBill(_jobId);
      state = JobDetailSuccess(job: success.job, bill: bill);
    } catch (e) {
      // Bill error doesn't prevent showing the job
      state = JobDetailSuccess(job: success.job, bill: success.bill);
    }
  }
}
