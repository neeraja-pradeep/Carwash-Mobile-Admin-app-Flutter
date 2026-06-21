import '../../domain/entities/service_request.dart';
import '../../../../core/status/service_request_status.dart';

/// Immutable UI filter + sort state for the service-requests list.
///
/// All updates produce a new instance via [copyWith]; the controller in
/// `service_requests_providers.dart` owns the mutation.
class ServiceRequestsFilterState {
  const ServiceRequestsFilterState({
    this.query = '',
    this.kind,
    this.status,
    this.sort = 'recent',
  });

  /// Search query (matches request id, customer name, customer phone).
  final String query;

  /// Optional kind sub-filter (`SrKind.driver` / `SrKind.inspection`).
  final SrKind? kind;

  /// Optional status filter.
  final ServiceRequestStatus? status;

  /// Sort key: `'recent'` | `'upcoming'` | `'status'`.
  final String sort;

  /// Number of active filter chips (kind + status).
  int get activeFilterCount =>
      (kind != null ? 1 : 0) + (status != null ? 1 : 0);

  ServiceRequestsFilterState copyWith({
    String? query,
    SrKind? kind,
    ServiceRequestStatus? status,
    String? sort,
    bool clearKind = false,
    bool clearStatus = false,
  }) {
    return ServiceRequestsFilterState(
      query: query ?? this.query,
      kind: clearKind ? null : (kind ?? this.kind),
      status: clearStatus ? null : (status ?? this.status),
      sort: sort ?? this.sort,
    );
  }
}

/// Returns the list as-is since filtering is handled server-side by the API.
/// The API already applies kind, status, search, and sort filters.
List<ServiceRequest> applyServiceRequestsFilter(
  List<ServiceRequest> list,
  ServiceRequestsFilterState filter,
) {
  return list;
}
