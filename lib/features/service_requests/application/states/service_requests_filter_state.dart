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

/// Applies [filter] to [list] and returns a sorted, filtered copy.
List<ServiceRequest> applyServiceRequestsFilter(
  List<ServiceRequest> list,
  ServiceRequestsFilterState filter,
) {
  var result = list;

  // Kind sub-filter.
  if (filter.kind != null) {
    result = result.where((r) => r.kind == filter.kind).toList();
  }

  // Status sub-filter.
  if (filter.status != null) {
    result = result.where((r) => r.status == filter.status).toList();
  }

  // Search: id, customer name, customer phone.
  final q = filter.query.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((r) {
      return r.id.toLowerCase().contains(q) ||
          r.customer.name.toLowerCase().contains(q) ||
          r.customer.phone.toLowerCase().contains(q);
    }).toList();
  }

  // Sort.
  result = List<ServiceRequest>.from(result);
  switch (filter.sort) {
    case 'upcoming':
      // Keep original order as proxy (when is a display string; no real parse).
      break;
    case 'status':
      result.sort((a, b) => a.status.order.compareTo(b.status.order));
    default: // 'recent' — newest first (reverse of list order which is newest-first).
      break;
  }

  return result;
}
