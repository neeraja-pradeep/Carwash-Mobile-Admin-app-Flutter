import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/customer.dart';
import '../../domain/repositories/customers_repository.dart';
import '../../infrastructure/data_sources/local/customers_local_ds.dart';
import '../../infrastructure/repositories/customers_repository_impl.dart';
import '../states/customers_filter_state.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────

/// Local data source provider (swapped for a remote+cache source in the API
/// phase).
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

/// All customers. autoDispose to avoid fetching on app startup.
final customersProvider = FutureProvider.autoDispose<List<Customer>>(
  (ref) => ref.watch(customersRepositoryProvider).fetchCustomers(),
);

/// A single customer by id. autoDispose + family so each detail screen gets
/// its own slot, cleared when the screen is gone.
final customerByIdProvider =
    FutureProvider.autoDispose.family<Customer?, String>(
  (ref, id) => ref.watch(customersRepositoryProvider).fetchCustomerById(id),
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

/// Derived, filtered+sorted customers (keeps widget `build` free of logic).
final filteredCustomersProvider =
    Provider.autoDispose<AsyncValue<List<Customer>>>((ref) {
  final customers = ref.watch(customersProvider);
  final filter = ref.watch(customersFilterProvider);
  return customers.whenData((list) => applyCustomerFilter(list, filter));
});

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
