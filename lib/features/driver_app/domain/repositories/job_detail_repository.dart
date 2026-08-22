import '../entities/job_detail.dart';
import '../entities/bill.dart';
import '../entities/cash_collection.dart';

abstract class JobDetailRepository {
  Future<JobDetail> getJobDetail(String jobId);
  Future<JobDetail> arrive(String jobId);
  Future<JobDetail> verifyStartOtp(String jobId, String otp);
  Future<JobDetail> verifyEndOtp(String jobId, String otp);
  Future<CashCollection> collectCash(String jobId, String amount);
  Future<Bill> getFinalBill(String jobId);
}
