import '../entities/availability.dart';
import '../entities/stats.dart';
import '../entities/job_feed.dart';

abstract class DriverHomeRepository {
  /// Get current worker availability status
  Future<Availability> getAvailability();

  /// Set worker online/offline status
  Future<Availability> setAvailability({required bool online});

  /// Get worker stats for a period
  Future<Stats> getStats({
    String? period = 'today',
    String? start,
    String? end,
  });

  /// Get job feed (active now + up next)
  Future<JobFeed> getJobFeed({String? date});
}
