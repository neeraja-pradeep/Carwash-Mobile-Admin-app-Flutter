import '../../domain/entities/payout.dart';
import '../../domain/repositories/payouts_repository.dart';
import '../data_sources/local/payouts_local_ds.dart';

/// Fulfils [PayoutsRepository] from the local static data source.
class PayoutsRepositoryImpl implements PayoutsRepository {
  const PayoutsRepositoryImpl(this._local);

  final PayoutsLocalDs _local;

  @override
  Future<List<Payout>> fetchPayouts() => _local.fetchPayouts();
}
