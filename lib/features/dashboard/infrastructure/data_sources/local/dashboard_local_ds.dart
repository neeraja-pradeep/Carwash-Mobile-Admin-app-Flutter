import '../../../domain/entities/activity_item.dart';
import '../../../domain/entities/dashboard_snapshot.dart';
import '../../../domain/entities/hiring_snapshot.dart';

/// Local data source for dashboard (deprecated - use API instead).
/// Kept only for emergency fallback if API is completely unavailable.
class DashboardLocalDs {
  const DashboardLocalDs();

  /// Deprecated: Use DashboardApi instead. Throws to force API usage.
  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    throw UnimplementedError(
      'Mock data removed. Dashboard now uses API exclusively. '
      'If you see this error, the API call failed.',
    );
  }

  /// Deprecated: Use DashboardApi instead. Throws to force API usage.
  Future<HiringSnapshot> fetchHiringSnapshot() async {
    throw UnimplementedError(
      'Mock data removed. Dashboard now uses API exclusively. '
      'If you see this error, the API call failed.',
    );
  }

  /// Deprecated: Use DashboardApi instead. Throws to force API usage.
  Future<List<ActivityItem>> fetchActivityFeed() async {
    throw UnimplementedError(
      'Mock data removed. Dashboard now uses API exclusively. '
      'If you see this error, the API call failed.',
    );
  }
}
