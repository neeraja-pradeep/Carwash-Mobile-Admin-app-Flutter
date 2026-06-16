import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../../infrastructure/data_sources/local/shops_local_ds.dart';
import '../../infrastructure/repositories/shops_repository_impl.dart';
import '../states/shops_filter_state.dart';

// ─── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (swapped for remote+cache in the API phase).
final shopsLocalDsProvider = Provider<ShopsLocalDs>(
  (ref) => const ShopsLocalDs(),
);

/// The shops repository (domain contract → infrastructure impl).
final shopsRepositoryProvider = Provider<ShopsRepository>(
  (ref) => ShopsRepositoryImpl(ref.watch(shopsLocalDsProvider)),
);

// ─── Read providers ───────────────────────────────────────────────────────────

/// All shops. Kept alive so back-navigation is instant (warm cache).
final shopsProvider = FutureProvider<List<Shop>>(
  (ref) => ref.watch(shopsRepositoryProvider).fetchShops(),
);

/// Single shop by id (autoDispose so detail screens reset when popped).
final shopByIdProvider =
    FutureProvider.autoDispose.family<Shop?, String>((ref, id) async {
  final shops = await ref.watch(shopsProvider.future);
  try {
    return shops.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

/// All holidays.
final holidaysProvider = FutureProvider<List<Holiday>>(
  (ref) => ref.watch(shopsRepositoryProvider).fetchHolidays(),
);

/// Holidays for a specific shop (autoDispose).
final shopHolidaysProvider =
    FutureProvider.autoDispose.family<List<Holiday>, String>((ref, shopId) async {
  final holidays = await ref.watch(holidaysProvider.future);
  final result = holidays.where((h) => h.shopIds.contains(shopId)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return result;
});

// ─── UI filter/sort state providers (autoDispose) ─────────────────────────────

/// Committed filter state for the shops list screen.
final shopsFilterProvider =
    StateNotifierProvider.autoDispose<ShopsFilterController, ShopsFilterState>(
  (ref) => ShopsFilterController(),
);

/// Derived filtered+sorted shops list.
final filteredShopsProvider =
    Provider.autoDispose<AsyncValue<List<Shop>>>((ref) {
  final shops = ref.watch(shopsProvider);
  final filter = ref.watch(shopsFilterProvider);
  return shops.whenData((list) => applyShopsFilter(list, filter));
});

/// Working copy of the filter while the filter sheet is open.
/// autoDispose resets it each time the sheet is closed/re-opened.
final shopsFilterDraftProvider =
    StateProvider.autoDispose<ShopsFilterState>(
  (ref) => ref.read(shopsFilterProvider),
);

// ─── Filter controller ────────────────────────────────────────────────────────

/// Owns the shops filter state; all updates produce a new state via copyWith.
class ShopsFilterController extends StateNotifier<ShopsFilterState> {
  ShopsFilterController() : super(const ShopsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);
  void setSort(String value) => state = state.copyWith(sort: value);
  void apply(ShopsFilterState next) => state = next;
  void reset() => state = const ShopsFilterState();

  void removeStatus() => state = state.copyWith(status: null);
  void removeType(String t) =>
      state = state.copyWith(types: state.types.where((x) => x != t).toList());
  void removeRating() => state = state.copyWith(rating: 'any');
}
