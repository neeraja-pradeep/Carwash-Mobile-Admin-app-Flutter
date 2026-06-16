import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../data_sources/local/shops_local_ds.dart';

/// Concrete shop repository backed by [ShopsLocalDs].
///
/// In the API phase, replace the [ShopsLocalDs] call with a remote data source
/// + optional Hive cache — the domain contract and providers remain unchanged.
class ShopsRepositoryImpl implements ShopsRepository {
  const ShopsRepositoryImpl(this._ds);

  final ShopsLocalDs _ds;

  @override
  Future<List<Shop>> fetchShops() => _ds.fetchShops();

  @override
  Future<List<Holiday>> fetchHolidays() => _ds.fetchHolidays();
}
