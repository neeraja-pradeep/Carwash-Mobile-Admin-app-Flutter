import '../../domain/entities/schedule_day.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../data_sources/schedule_api.dart';
import '../models/schedule_day_model.dart';
import '../models/job_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleApi _api = ScheduleApi();

  @override
  Future<ScheduleResponse> getSchedule({
    String? from,
    String? to,
    int page = 1,
    int pageSize = 10,
  }) async {
    final model = await _api.getSchedule(
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
    return model.toEntity() as ScheduleResponse;
  }

  @override
  Future<List<Job>> getAvailableJobs({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _api.getAvailableJobs(page: page, pageSize: pageSize);
    final results = response['results'] as List<dynamic>;
    return results
        .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Job> claimCarwashJob(String bookingId) async {
    final response = await _api.claimCarwashJob(bookingId);
    final jobData = response['job'] as Map<String, dynamic>;
    return JobModel.fromJson(jobData);
  }

  @override
  Future<Job> claimDriverHireJob(String bookingId) async {
    final response = await _api.claimDriverHireJob(bookingId);
    final jobData = response['job'] as Map<String, dynamic>;
    return JobModel.fromJson(jobData);
  }

  @override
  Future<Map<String, dynamic>> getCarwashSummary(String bookingId) async {
    return await _api.getCarwashSummary(bookingId);
  }
}
