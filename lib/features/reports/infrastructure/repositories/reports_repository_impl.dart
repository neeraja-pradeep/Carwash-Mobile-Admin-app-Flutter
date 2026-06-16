import '../../domain/entities/daily_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import '../data_sources/local/reports_local_ds.dart';

/// Fulfils [ReportsRepository] from the local static data source.
class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._local);

  final ReportsLocalDs _local;

  @override
  Future<DailySummary> fetchDailySummary() => _local.fetchDailySummary();
}
