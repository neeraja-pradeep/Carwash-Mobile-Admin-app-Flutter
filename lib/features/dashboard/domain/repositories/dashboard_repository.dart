import '../entities/activity_item.dart';
import '../entities/dashboard_snapshot.dart';
import '../entities/hiring_snapshot.dart';

/// Abstract contract for reading dashboard data.
/// Pure domain layer — no implementation details.
abstract class DashboardRepository {
  /// Fetches the carwash operational snapshot for today.
  Future<DashboardSnapshot> fetchDashboardSnapshot();

  /// Fetches the driver hiring & inspection snapshot.
  Future<HiringSnapshot> fetchHiringSnapshot();

  /// Fetches the recent activity feed.
  Future<List<ActivityItem>> fetchActivityFeed();
}
