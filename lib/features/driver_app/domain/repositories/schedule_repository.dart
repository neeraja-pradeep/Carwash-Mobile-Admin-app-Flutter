import '../entities/schedule_day.dart';
import '../entities/job.dart';

abstract class ScheduleRepository {
  Future<ScheduleResponse> getSchedule({
    String? from,
    String? to,
    int page = 1,
    int pageSize = 10,
  });

  Future<List<Job>> getAvailableJobs({
    int page = 1,
    int pageSize = 10,
  });

  Future<Job> claimCarwashJob(String bookingId);

  Future<Job> claimDriverHireJob(String bookingId);

  Future<Map<String, dynamic>> getCarwashSummary(String bookingId);
}
