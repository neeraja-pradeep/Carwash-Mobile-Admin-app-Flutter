import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../domain/repositories/driver_app_repository.dart';
import '../data_sources/local/driver_app_local_ds.dart';

/// Fulfils [DriverAppRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class DriverAppRepositoryImpl implements DriverAppRepository {
  const DriverAppRepositoryImpl(this._local);

  final DriverAppLocalDs _local;

  @override
  Future<List<DriverJob>> fetchDriverJobs() => _local.fetchDriverJobs();

  @override
  Future<DriverEarnings> fetchDriverEarnings() => _local.fetchDriverEarnings();
}
