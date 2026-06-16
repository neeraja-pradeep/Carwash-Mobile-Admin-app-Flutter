import '../../domain/entities/refund.dart';
import '../../domain/repositories/refunds_repository.dart';
import '../data_sources/local/refunds_local_ds.dart';

/// Fulfils [RefundsRepository] from the local static data source.
class RefundsRepositoryImpl implements RefundsRepository {
  const RefundsRepositoryImpl(this._local);

  final RefundsLocalDs _local;

  @override
  Future<List<Refund>> fetchRefunds() => _local.fetchRefunds();
}
