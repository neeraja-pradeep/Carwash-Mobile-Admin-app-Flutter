import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../../infrastructure/data_sources/local/drivers_local_ds.dart';
import '../../infrastructure/repositories/drivers_repository_impl.dart';
import '../states/drivers_filter_state.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (founders fallback only).
final driversLocalDsProvider = Provider<DriversLocalDs>(
  (ref) => const DriversLocalDs(),
);

/// The drivers repository (domain contract → infrastructure impl).
final driversRepositoryProvider = Provider<DriversRepository>(
  (ref) => DriversRepositoryImpl(local: ref.watch(driversLocalDsProvider)),
);

/// API status string for a [DriverStatus] filter (`null` = all).
String? driverStatusParam(DriverStatus? status) => switch (status) {
      DriverStatus.online => 'active',
      DriverStatus.offline => 'inactive',
      DriverStatus.invited => 'invited',
      DriverStatus.suspended => 'suspended',
      null => null,
    };

// ── Entity providers ─────────────────────────────────────────────────────────

/// All drivers, filtered server-side by the committed status filter.
final fieldDriversProvider = FutureProvider.autoDispose<List<FieldDriver>>((ref) {
  final filter = ref.watch(driversFilterProvider);
  return ref
      .watch(driversRepositoryProvider)
      .fetchFieldDrivers(status: driverStatusParam(filter.status));
});

/// A single driver by id — hits the detail endpoint (rich blocks populated).
final fieldDriverByIdProvider =
    FutureProvider.autoDispose.family<FieldDriver?, String>((ref, id) {
  return ref.watch(driversRepositoryProvider).getDriverDetail(id);
});

/// The founders (Anand, Vishnu) — local fallback for the assignee resolver.
final foundersProvider = FutureProvider.autoDispose<List<TeamMember>>(
  (ref) => ref.watch(driversRepositoryProvider).fetchFounders(),
);

/// The inspectors (list-only tab).
final inspectorsProvider = FutureProvider.autoDispose<List<TeamMember>>(
  (ref) => ref.watch(driversRepositoryProvider).fetchInspectors(),
);

/// Resolves an assignee id across founders + inspectors + field drivers.
/// Used by bookings / service-request screens to show the assignee name/phone/role.
final assigneeByIdProvider = FutureProvider.autoDispose
    .family<({String name, String phone, String role})?, String>(
  (ref, id) async {
    // Search founders first
    final founders = await ref.watch(foundersProvider.future);
    for (final m in founders) {
      if (m.id == id) return (name: m.name, phone: m.phone, role: m.role);
    }
    // Then inspectors
    final inspectors = await ref.watch(inspectorsProvider.future);
    for (final m in inspectors) {
      if (m.id == id) return (name: m.name, phone: m.phone, role: m.role);
    }
    // Then field drivers
    final drivers = await ref.watch(fieldDriversProvider.future);
    for (final d in drivers) {
      if (d.id == id) return (name: d.name, phone: d.phone, role: d.role);
    }
    return null;
  },
);

// ── Mutations ─────────────────────────────────────────────────────────────────

/// Coordinates write operations and refreshes the relevant providers.
final driverMutationsProvider = Provider<DriverMutations>(
  (ref) => DriverMutations(ref),
);

class DriverMutations {
  DriverMutations(this._ref);

  final Ref _ref;

  DriversRepository get _repo => _ref.read(driversRepositoryProvider);

  void _invalidateLists() {
    _ref.invalidate(fieldDriversProvider);
    _ref.invalidate(inspectorsProvider);
  }

  Future<FieldDriver> hireDriver({
    required String fullName,
    required String phone,
    String? email,
    String? subRole,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) async {
    final created = await _repo.hireDriver(
      fullName: fullName,
      phone: phone,
      email: email,
      subRole: subRole,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
    );
    _invalidateLists();
    return created;
  }

  Future<FieldDriver> hireInspector({
    required String fullName,
    required String phone,
    String? email,
    required List<String> vehicleClasses,
    required String licenseNumber,
    required String licenseExpiry,
    required bool licenseVerified,
  }) async {
    final created = await _repo.hireInspector(
      fullName: fullName,
      phone: phone,
      email: email,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
    );
    _invalidateLists();
    return created;
  }

  Future<FieldDriver> updateDriver(
    String id, {
    String? fullName,
    String? email,
    String? status,
    String? subRole,
    List<String>? vehicleClasses,
    String? licenseNumber,
    String? licenseExpiry,
    bool? licenseVerified,
    String? phone,
  }) async {
    final updated = await _repo.updateDriver(
      id,
      fullName: fullName,
      email: email,
      status: status,
      subRole: subRole,
      vehicleClasses: vehicleClasses,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      licenseVerified: licenseVerified,
      phone: phone,
    );
    _invalidateLists();
    _ref.invalidate(fieldDriverByIdProvider(id));
    return updated;
  }

  Future<void> deleteDriver(String id) async {
    await _repo.deleteDriver(id);
    _invalidateLists();
    _ref.invalidate(fieldDriverByIdProvider(id));
  }

  Future<void> uploadDocument(
    String id, {
    required bool isInspector,
    required String filePath,
    required String kind,
    String side = 'front',
    String? name,
  }) async {
    await _repo.uploadDocument(
      id,
      isInspector: isInspector,
      filePath: filePath,
      kind: kind,
      side: side,
      name: name,
    );
    if (!isInspector) _ref.invalidate(fieldDriverByIdProvider(id));
    _invalidateLists();
  }

  Future<void> patchDocument(
    String id,
    String docId, {
    required bool isInspector,
    bool? frontVerified,
    bool? backVerified,
    bool? verified,
    String? name,
  }) async {
    await _repo.patchDocument(
      id,
      docId,
      isInspector: isInspector,
      frontVerified: frontVerified,
      backVerified: backVerified,
      verified: verified,
      name: name,
    );
    if (!isInspector) _ref.invalidate(fieldDriverByIdProvider(id));
  }

  Future<void> deleteDocument(
    String id,
    String docId, {
    required bool isInspector,
  }) async {
    await _repo.deleteDocument(id, docId, isInspector: isInspector);
    if (!isInspector) _ref.invalidate(fieldDriverByIdProvider(id));
  }
}

// ── UI state providers (autoDispose — reset on navigation) ───────────────────

/// Active segment: `'drivers'` | `'inspectors'`.
final driversSegmentProvider = StateProvider.autoDispose<String>(
  (ref) => 'drivers',
);

/// Committed filter state for the Drivers list.
final driversFilterProvider =
    StateNotifierProvider<DriversFilterController, DriversFilterState>(
  (ref) => DriversFilterController(),
);

/// Working copy of the filter while the filter sheet is open.
final driversFilterDraftProvider =
    StateProvider.autoDispose<DriversFilterState>(
  (ref) => ref.read(driversFilterProvider),
);

/// Derived field drivers — server already filters by status, so this just
/// passes the async value through (kept for the screen's existing call site).
final filteredFieldDriversProvider =
    Provider.autoDispose<AsyncValue<List<FieldDriver>>>((ref) {
  return ref.watch(fieldDriversProvider);
});

/// Owns the drivers filter state.
class DriversFilterController extends StateNotifier<DriversFilterState> {
  DriversFilterController() : super(const DriversFilterState());

  /// Sets the status filter; passing `null` clears it.
  void setStatus(DriverStatus? status) =>
      state = state.copyWith(status: status, clearStatus: status == null);

  /// Applies a draft state wholesale.
  void apply(DriversFilterState next) => state = next;

  /// Resets all filters.
  void reset() => state = const DriversFilterState();
}

/// Refetches the drivers screen (both segments). Shared by pull-to-refresh and
/// the navigate-back refresh wired up in `app_router.dart`.
Future<void> refreshDrivers(WidgetRef ref) async {
  ref.invalidate(fieldDriversProvider);
  ref.invalidate(foundersProvider);
  ref.invalidate(inspectorsProvider);
  await ref.read(fieldDriversProvider.future);
}
