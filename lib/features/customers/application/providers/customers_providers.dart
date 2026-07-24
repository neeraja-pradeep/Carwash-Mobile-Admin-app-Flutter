import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../../infrastructure/data_sources/local/customers_local_ds.dart';
import '../../infrastructure/repositories/customers_repository_impl.dart';
import '../states/customers_filter_state.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────

/// Local data source provider (list fallback only).
final customersLocalDsProvider = Provider<CustomersLocalDs>(
  (ref) => const CustomersLocalDs(),
);

/// The customers repository (domain contract → infrastructure impl).
final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepositoryImpl(
    local: ref.watch(customersLocalDsProvider),
  ),
);

// ─── Data providers ───────────────────────────────────────────────────────────

/// Customers list, fetched server-side from the committed filter/sort/search.
/// autoDispose to avoid fetching on app startup; re-runs whenever the filter
/// state changes.
final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  final filter = ref.watch(customersFilterProvider);
  return ref.watch(customersRepositoryProvider).fetchCustomers(
        search: filter.query.trim().isEmpty ? null : filter.query.trim(),
        status: filter.status,
        joined: filter.joinedParam,
        bookingCount: filter.bookingCountParam,
        sort: filter.sortParam,
      );
});

/// A single customer by id — calls the dedicated detail endpoint. autoDispose +
/// family so each detail screen gets its own slot, cleared when the screen is gone.
final customerByIdProvider =
    FutureProvider.autoDispose.family<Customer?, String>(
  (ref, id) => ref.watch(customersRepositoryProvider).fetchCustomerById(id),
);

/// A page of a customer's booking history. Family keyed by `(id, page)`.
final customerHistoryProvider = FutureProvider.autoDispose
    .family<CustomerHistoryPage, ({String id, int page})>(
  (ref, arg) => ref
      .watch(customersRepositoryProvider)
      .fetchCustomerHistory(arg.id, page: arg.page),
);

/// Search customers by query. autoDispose so it clears when not in use.
final searchCustomersProvider =
    FutureProvider.autoDispose.family<List<Customer>, String>(
  (ref, query) =>
      ref.watch(customersRepositoryProvider).searchCustomers(query),
);

/// Create a new customer. autoDispose + family with params.
final createCustomerProvider =
    FutureProvider.autoDispose.family<Customer, Map<String, dynamic>>(
  (ref, params) => ref.watch(customersRepositoryProvider).createCustomer(
        phone: params['phone'] as String,
        fullName: params['fullName'] as String,
        otpCode: params['otpCode'] as String?,
        email: params['email'] as String?,
      ),
);

// ─── UI state providers (autoDispose — reset when list screen leaves) ─────────

/// Committed filter/sort/search state for the Customers list screen.
final customersFilterProvider =
    StateNotifierProvider.autoDispose<CustomersFilterController,
        CustomersFilterState>(
  (ref) => CustomersFilterController(),
);

/// Working copy of the filter while the filter sheet is open.
final customersFilterDraftProvider =
    StateProvider.autoDispose<CustomersFilterState>(
  (ref) => ref.read(customersFilterProvider),
);

/// The list screen's customers. Filtering/sorting now happens on the server
/// (see [customersProvider]); this just forwards the async value so the screen
/// API stays unchanged.
final filteredCustomersProvider =
    Provider.autoDispose<AsyncValue<List<Customer>>>((ref) {
  return ref.watch(customersProvider);
});

// ─── Mutation helpers ──────────────────────────────────────────────────────────

/// Saves founder notes for [id], then refreshes the detail provider.
Future<void> saveFounderNotes(WidgetRef ref, String id, String notes) async {
  await ref.read(customersRepositoryProvider).updateFounderNotes(id, notes);
  _refreshCustomer(ref, id);
}

/// Blocks [id] with an optional reason enum + notes, then refreshes.
Future<void> blockCustomer(
  WidgetRef ref,
  String id, {
  String? reason,
  String? notes,
}) async {
  await ref
      .read(customersRepositoryProvider)
      .blockCustomer(id, reason: reason, notes: notes);
  _refreshCustomer(ref, id);
}

/// Unblocks [id], then refreshes.
Future<void> unblockCustomer(WidgetRef ref, String id) async {
  await ref.read(customersRepositoryProvider).unblockCustomer(id);
  _refreshCustomer(ref, id);
}

void _refreshCustomer(WidgetRef ref, String id) {
  // Defer invalidation until after the current frame. Invalidating a watched
  // provider synchronously while the note/confirmation modal route is tearing
  // down throws a `_dependents.isEmpty` assertion (the red flash) and aborts the
  // detail refetch, which then surfaces as "Customer not found". Running it in a
  // post-frame callback lets the modal fully unmount first.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.invalidate(customerByIdProvider(id));
    // The list shows the active/blocked badge + stats, so refresh it too.
    ref.invalidate(customersProvider);
  });
}

// ─── Controller ──────────────────────────────────────────────────────────────

/// Owns the customers filter state; all updates produce a new state via
/// copyWith.
class CustomersFilterController extends StateNotifier<CustomersFilterState> {
  CustomersFilterController() : super(const CustomersFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(String value) => state = state.copyWith(sort: value);

  void apply(CustomersFilterState next) => state = next;

  void reset() => state = const CustomersFilterState();

  void removeStatus() => state = state.copyWith(status: null);

  void removeJoined() => state = state.copyWith(joined: 'any');

  void removeVolume() => state = state.copyWith(volume: 'any');
}

/// Refetches the customers list. Shared by pull-to-refresh and the
/// navigate-back refresh wired up in `app_router.dart`.
Future<void> refreshCustomers(WidgetRef ref) async {
  ref.invalidate(customersProvider);
  await ref.read(customersProvider.future);
}
