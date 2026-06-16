import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_requests_repository.dart';
import '../../infrastructure/data_sources/local/service_requests_local_ds.dart';
import '../../infrastructure/repositories/service_requests_repository_impl.dart';
import '../states/service_requests_filter_state.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (swapped for a remote+cache source in the API phase).
final serviceRequestsLocalDsProvider = Provider<ServiceRequestsLocalDs>(
  (ref) => const ServiceRequestsLocalDs(),
);

/// The service-requests repository (domain contract → infrastructure impl).
final serviceRequestsRepositoryProvider = Provider<ServiceRequestsRepository>(
  (ref) => ServiceRequestsRepositoryImpl(
    ref.watch(serviceRequestsLocalDsProvider),
  ),
);

// ── Entity providers ─────────────────────────────────────────────────────────

/// All service requests (read). Kept alive so navigation back is instant.
final serviceRequestsProvider = FutureProvider<List<ServiceRequest>>(
  (ref) =>
      ref.watch(serviceRequestsRepositoryProvider).fetchServiceRequests(),
);

/// A single service request by id (autoDispose — resets when the detail
/// screen is gone).
final serviceRequestByIdProvider =
    FutureProvider.autoDispose.family<ServiceRequest?, String>((ref, id) async {
  final requests = await ref.watch(serviceRequestsProvider.future);
  try {
    return requests.firstWhere((r) => r.id == id);
  } on StateError {
    return null;
  }
});

// ── UI state providers (autoDispose — reset on navigation away) ──────────────

/// Committed filter + sort + search state for the requests list.
final serviceRequestsFilterProvider = StateNotifierProvider.autoDispose<
    ServiceRequestsFilterController, ServiceRequestsFilterState>(
  (ref) => ServiceRequestsFilterController(),
);

/// Working copy of the filter while the filter sheet is open.
final serviceRequestsFilterDraftProvider =
    StateProvider.autoDispose<ServiceRequestsFilterState>(
  (ref) => ref.read(serviceRequestsFilterProvider),
);

/// Derived, filtered + sorted requests (keeps `build` free of logic).
final filteredServiceRequestsProvider =
    Provider.autoDispose<AsyncValue<List<ServiceRequest>>>((ref) {
  final requests = ref.watch(serviceRequestsProvider);
  final filter = ref.watch(serviceRequestsFilterProvider);
  return requests.whenData(
    (list) => applyServiceRequestsFilter(list, filter),
  );
});

// ── Filter controller ────────────────────────────────────────────────────────

/// Owns the service-requests filter state; all updates produce a new state via
/// [copyWith].
class ServiceRequestsFilterController
    extends StateNotifier<ServiceRequestsFilterState> {
  ServiceRequestsFilterController() : super(const ServiceRequestsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(String value) => state = state.copyWith(sort: value);

  void apply(ServiceRequestsFilterState next) => state = next;

  void reset() => state = const ServiceRequestsFilterState();

  void removeKind() => state = state.copyWith(clearKind: true);

  void removeStatus() => state = state.copyWith(clearStatus: true);
}
