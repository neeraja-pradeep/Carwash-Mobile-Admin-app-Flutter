import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_requests_repository.dart';
import '../data_sources/local/service_requests_local_ds.dart';

/// Fulfils [ServiceRequestsRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class ServiceRequestsRepositoryImpl implements ServiceRequestsRepository {
  const ServiceRequestsRepositoryImpl(this._local);

  final ServiceRequestsLocalDs _local;

  @override
  Future<List<ServiceRequest>> fetchServiceRequests() =>
      _local.fetchServiceRequests();
}
