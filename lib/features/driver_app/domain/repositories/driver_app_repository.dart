import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../../drivers/domain/entities/driver_job.dart';

/// Contract for reading the signed-in driver's jobs and earnings.
/// Pure abstract — no implementation details here.
abstract class DriverAppRepository {
  /// All jobs for the signed-in driver (active + upcoming + completed).
  Future<List<DriverJob>> fetchDriverJobs();

  /// The signed-in driver's earnings summary (today, week, bar chart, breakdown).
  Future<DriverEarnings> fetchDriverEarnings();
}
