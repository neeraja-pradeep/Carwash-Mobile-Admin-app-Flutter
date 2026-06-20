import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/dashboard_api.dart';

/// Fulfils [DashboardRepository] from remote API exclusively.
///
/// No fallback to mock data. All calls go to the API.
/// If API fails, the error is propagated to the presentation layer.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    DashboardApi? api,
  }) : _api = api ?? DashboardApi();

  final DashboardApi _api;

  @override
  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    final response = await _api.getDashboardSnapshot();
    return response.toDomain();
  }

  @override
  Future<HiringSnapshot> fetchHiringSnapshot() async {
    final response = await _api.getDashboardSnapshot();
    return response.driverInspector.toHiringSnapshot();
  }

  @override
  Future<List<ActivityItem>> fetchActivityFeed() async {
    final responses = await _api.getRecentActivity();
    return responses.map((r) => r.toDomain()).toList();
  }
}
