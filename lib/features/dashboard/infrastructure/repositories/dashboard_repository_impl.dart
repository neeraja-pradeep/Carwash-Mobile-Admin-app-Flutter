import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/local/dashboard_local_ds.dart';

/// Fulfils [DashboardRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._local);

  final DashboardLocalDs _local;

  @override
  Future<DashboardSnapshot> fetchDashboardSnapshot() =>
      _local.fetchDashboardSnapshot();

  @override
  Future<HiringSnapshot> fetchHiringSnapshot() =>
      _local.fetchHiringSnapshot();

  @override
  Future<List<ActivityItem>> fetchActivityFeed() =>
      _local.fetchActivityFeed();
}
