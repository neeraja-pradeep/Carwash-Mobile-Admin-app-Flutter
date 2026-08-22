import '../../domain/entities/job_detail.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/cash_collection.dart';
import '../../domain/repositories/job_detail_repository.dart';
import '../data_sources/job_detail_api.dart';

class JobDetailRepositoryImpl implements JobDetailRepository {
  final JobDetailApi _api = JobDetailApi();

  @override
  Future<JobDetail> getJobDetail(String jobId) async {
    final model = await _api.getJobDetail(jobId);
    return model.toEntity();
  }

  @override
  Future<JobDetail> arrive(String jobId) async {
    final model = await _api.arrive(jobId);
    return model.toEntity();
  }

  @override
  Future<JobDetail> verifyStartOtp(String jobId, String otp) async {
    final model = await _api.verifyStartOtp(jobId, otp);
    return model.toEntity();
  }

  @override
  Future<JobDetail> verifyEndOtp(String jobId, String otp) async {
    final model = await _api.verifyEndOtp(jobId, otp);
    return model.toEntity();
  }

  @override
  Future<CashCollection> collectCash(String jobId, String amount) async {
    final model = await _api.collectCash(jobId, amount);
    return model.toEntity();
  }

  @override
  Future<Bill> getFinalBill(String jobId) async {
    final model = await _api.getFinalBill(jobId);
    return model.toEntity();
  }
}
