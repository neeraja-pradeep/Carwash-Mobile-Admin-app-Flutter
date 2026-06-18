import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../entities/worker_profile.dart';

/// Contract for reading the signed-in driver's jobs, earnings, and profile.
/// Pure abstract — no implementation details here.
abstract class DriverAppRepository {
  /// All jobs for the signed-in driver (active + upcoming + completed).
  Future<List<DriverJob>> fetchDriverJobs();

  /// The signed-in driver's earnings summary (today, week, bar chart, breakdown).
  Future<DriverEarnings> fetchDriverEarnings();

  /// The signed-in worker's profile information.
  Future<WorkerProfile> fetchWorkerProfile();
}
