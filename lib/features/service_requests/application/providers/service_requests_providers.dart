import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/status/service_request_status.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_requests_repository.dart';
import '../../infrastructure/models/driver_inspection_detail_response_model.dart';
import '../../infrastructure/models/create_request_response_model.dart';
import '../../infrastructure/repositories/service_requests_repository_impl.dart';
import '../states/service_requests_filter_state.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// The service-requests repository (domain contract → infrastructure impl).
final serviceRequestsRepositoryProvider = Provider<ServiceRequestsRepository>(
  (ref) => ServiceRequestsRepositoryImpl(),
);

// ── Query parameter provider ──────────────────────────────────────────────────

/// Encapsulates query parameters for service requests.
class ServiceRequestsQuery {
  final String? search;
  final String? requestType;
  final String? status;
  final String? sort;

  ServiceRequestsQuery({
    this.search,
    this.requestType,
    this.status,
    this.sort = 'recent',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceRequestsQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          requestType == other.requestType &&
          status == other.status &&
          sort == other.sort;

  @override
  int get hashCode =>
      search.hashCode ^
      requestType.hashCode ^
      status.hashCode ^
      sort.hashCode;
}

/// Derives query parameters from filter state.
final serviceRequestsQueryProvider =
    Provider<ServiceRequestsQuery>((ref) {
  final filter = ref.watch(serviceRequestsFilterProvider);
  final statusKey = filter.status != null
      ? switch (filter.status!) {
          ServiceRequestStatus.created => 'new',
          ServiceRequestStatus.inProgress => 'in_progress',
          ServiceRequestStatus.contacted => 'contacted',
          ServiceRequestStatus.assigned => 'assigned',
          ServiceRequestStatus.arrived => 'arrived',
          ServiceRequestStatus.completed => 'completed',
          ServiceRequestStatus.cancelled => 'cancelled',
        }
      : null;

  return ServiceRequestsQuery(
    search: filter.query.isNotEmpty ? filter.query : null,
    requestType: filter.kind?.name,
    status: statusKey,
    sort: filter.sort,
  );
});

// ── Entity providers ─────────────────────────────────────────────────────────

/// All service requests — autoDispose so re-entering the screen refetches.
final serviceRequestsProvider = FutureProvider.autoDispose<List<ServiceRequest>>(
  (ref) {
    final query = ref.watch(serviceRequestsQueryProvider);
    return ref.watch(serviceRequestsRepositoryProvider).fetchServiceRequests(
          search: query.search,
          requestType: query.requestType,
          status: query.status,
          sort: query.sort,
        );
  },
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

// ── Detail screen providers ──────────────────────────────────────────────────

/// Get detail for a single request by id (cached).
final serviceRequestDetailProvider =
    FutureProvider.family<DriverInspectionDetailResponse, int>((ref, id) {
  return ref.watch(serviceRequestsRepositoryProvider).getDetail(id);
});

/// Get assignable workers for a request
final assignableWorkersProvider =
    FutureProvider.family<AssignableWorkersResponse, int>((ref, id) {
  return ref.watch(serviceRequestsRepositoryProvider).getAssignableWorkers(id);
});

// ── Action state providers ───────────────────────────────────────────────────

/// State for tracking action operations (assign, status, etc)
class DetailActionState {
  final bool isLoading;
  final String? error;
  final bool success;

  const DetailActionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  DetailActionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return DetailActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Controller for detail actions
class DetailActionController extends StateNotifier<DetailActionState> {
  DetailActionController(this._ref) : super(const DetailActionState());

  final Ref _ref;

  Future<void> assignWorker({
    required int id,
    required int workerId,
    required int slotId,
    required String workerType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(serviceRequestsRepositoryProvider)
          .assignWorker(
            id: id,
            workerId: workerId,
            slotId: slotId,
            workerType: workerType,
          );
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the assignee status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus({
    required int id,
    required String status,
    String? note,
    String? quotedFee,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(serviceRequestsRepositoryProvider)
          .updateStatus(
            id: id,
            status: status,
            note: note,
            quotedFee: quotedFee,
          );
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markArrived(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(serviceRequestsRepositoryProvider).markArrived(id);
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyStartOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(serviceRequestsRepositoryProvider)
          .verifyStartOtp(
            id: id,
            otp: otp,
            latitude: latitude,
            longitude: longitude,
            locationText: locationText,
          );
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyEndOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(serviceRequestsRepositoryProvider)
          .verifyEndOtp(
            id: id,
            otp: otp,
            latitude: latitude,
            longitude: longitude,
            locationText: locationText,
          );
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelRequest(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(serviceRequestsRepositoryProvider).cancelRequest(id);
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate detail + list so the status refreshes everywhere.
      _ref.invalidate(serviceRequestDetailProvider(id));
      _ref.invalidate(serviceRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const DetailActionState();
}

/// State notifier provider for detail actions
final detailActionProvider =
    StateNotifierProvider<DetailActionController, DetailActionState>(
  (ref) => DetailActionController(ref),
);

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

// ── Create request providers ──────────────────────────────────────────────────

/// Search customers by phone/name
final searchCustomersProvider =
    FutureProvider.family<CustomerListResponse, String>((ref, query) {
  return ref.watch(serviceRequestsRepositoryProvider).searchCustomers(query);
});

/// Create new customer
final createCustomerProvider =
    FutureProvider.family<CreateCustomerResponse, Map<String, dynamic>>(
  (ref, params) {
    return ref.watch(serviceRequestsRepositoryProvider).createCustomer(
          phone: params['phone'] as String,
          fullName: params['fullName'] as String,
          otpCode: params['otpCode'] as String?,
          email: params['email'] as String?,
        );
  },
);

/// Create new service request
final createServiceRequestProvider =
    FutureProvider.family<CreateRequestResponse, Map<String, dynamic>>(
  (ref, params) {
    return ref.watch(serviceRequestsRepositoryProvider).createRequest(
          customerId: params['customerId'] as int,
          requestType: params['requestType'] as String,
          tripType: params['tripType'] as String?,
          inspectionType: params['inspectionType'] as String?,
          vehicleText: params['vehicleText'] as String?,
          carId: params['carId'] as int?,
          appointmentDate: params['appointmentDate'] as String,
          startSlot: params['startSlot'] as int?,
          startTime: params['startTime'] as String?,
          addressText: params['addressText'] as String?,
          latitude: params['latitude'] as double?,
          longitude: params['longitude'] as double?,
          dropAddressText: params['dropAddressText'] as String?,
          dropLatitude: params['dropLatitude'] as double?,
          dropLongitude: params['dropLongitude'] as double?,
          quotedFee: params['quotedFee'] as String?,
          customerNote: params['customerNote'] as String?,
          hourlyPackage: params['hourlyPackage'] as String?,
          requestedHours: params['requestedHours'] as int?,
        );
  },
);
