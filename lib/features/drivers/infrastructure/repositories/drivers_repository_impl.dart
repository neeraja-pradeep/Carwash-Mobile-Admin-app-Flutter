import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../data_sources/local/drivers_local_ds.dart';

/// Fulfils [DriversRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class DriversRepositoryImpl implements DriversRepository {
  const DriversRepositoryImpl(this._local);

  final DriversLocalDs _local;

  @override
  Future<List<FieldDriver>> fetchFieldDrivers() => _local.fetchFieldDrivers();

  @override
  Future<List<TeamMember>> fetchFounders() => _local.fetchFounders();

  @override
  Future<List<TeamMember>> fetchInspectors() => _local.fetchInspectors();
}
