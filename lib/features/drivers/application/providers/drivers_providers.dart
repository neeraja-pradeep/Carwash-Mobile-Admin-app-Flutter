import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../../infrastructure/data_sources/local/drivers_local_ds.dart';
import '../../infrastructure/repositories/drivers_repository_impl.dart';
import '../states/drivers_filter_state.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (swapped for a remote+cache source in the API phase).
final driversLocalDsProvider = Provider<DriversLocalDs>(
  (ref) => const DriversLocalDs(),
);

/// The drivers repository (domain contract → infrastructure impl).
final driversRepositoryProvider = Provider<DriversRepository>(
  (ref) => DriversRepositoryImpl(ref.watch(driversLocalDsProvider)),
);

// ── Entity providers ─────────────────────────────────────────────────────────

/// All four hired field drivers. Kept alive so navigation back is instant.
final fieldDriversProvider = FutureProvider<List<FieldDriver>>(
  (ref) => ref.watch(driversRepositoryProvider).fetchFieldDrivers(),
);

/// A single field driver by id (autoDispose — resets when the detail screen
/// is gone).
final fieldDriverByIdProvider =
    FutureProvider.autoDispose.family<FieldDriver?, String>((ref, id) async {
  final drivers = await ref.watch(fieldDriversProvider.future);
  try {
    return drivers.firstWhere((d) => d.id == id);
  } on StateError {
    return null;
  }
});

/// The two founders (Anand, Vishnu).
final foundersProvider = FutureProvider<List<TeamMember>>(
  (ref) => ref.watch(driversRepositoryProvider).fetchFounders(),
);

/// The two inspectors (Ravi Menon, Salim K).
final inspectorsProvider = FutureProvider<List<TeamMember>>(
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

// ── UI state providers (autoDispose — reset on navigation) ───────────────────

/// Active segment: `'drivers'` | `'inspectors'`.
final driversSegmentProvider = StateProvider.autoDispose<String>(
  (ref) => 'drivers',
);

/// Committed filter state for the Drivers list.
final driversFilterProvider =
    StateNotifierProvider.autoDispose<DriversFilterController, DriversFilterState>(
  (ref) => DriversFilterController(),
);

/// Working copy of the filter while the filter sheet is open.
final driversFilterDraftProvider =
    StateProvider.autoDispose<DriversFilterState>(
  (ref) => ref.read(driversFilterProvider),
);

/// Derived, filtered field drivers.
final filteredFieldDriversProvider =
    Provider.autoDispose<AsyncValue<List<FieldDriver>>>((ref) {
  final drivers = ref.watch(fieldDriversProvider);
  final filter = ref.watch(driversFilterProvider);
  return drivers.whenData((list) {
    if (filter.status == null) return list;
    return list.where((d) => d.status == filter.status).toList();
  });
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
