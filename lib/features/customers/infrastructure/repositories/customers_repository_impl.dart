import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../data_sources/local/customers_local_ds.dart';

/// Fulfils [CustomersRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class CustomersRepositoryImpl implements CustomersRepository {
  const CustomersRepositoryImpl(this._local);

  final CustomersLocalDs _local;

  @override
  Future<List<Customer>> fetchCustomers() => _local.fetchCustomers();

  @override
  Future<Customer?> fetchCustomerById(String id) =>
      _local.fetchCustomerById(id);
}
