import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shops_repository.dart';
import '../../infrastructure/repositories/shops_repository_impl.dart';
import '../states/shops_filter_state.dart';

export '../../domain/repositories/shops_repository.dart' show ShopsPage;

// ─── Data layer providers ─────────────────────────────────────────────────────

/// The shops repository (domain contract → infrastructure impl with API).
final shopsRepositoryProvider = Provider<ShopsRepository>(
  (ref) => ShopsRepositoryImpl(),
);

// ─── UI filter/sort state providers (autoDispose) ─────────────────────────────

/// Committed filter state for the shops list screen.
final shopsFilterProvider =
    StateNotifierProvider.autoDispose<ShopsFilterController, ShopsFilterState>(
  (ref) => ShopsFilterController(),
);

/// All shops (backward compatible - loads first page only).
/// Used by bookings, payouts, and other screens that need a simple list.
final shopsProvider = FutureProvider.autoDispose<List<Shop>>(
  (ref) async {
    final repository = ref.watch(shopsRepositoryProvider);
    // Load all shops from API (no filters, just first page for compatibility)
    final page = await repository.fetchShops(
      page: 1,
      pageSize: 100,
    );
    return page.items;
  },
);

/// Current page number for paginated shops list.
final shopsPageProvider = StateProvider.autoDispose<int>(
  (ref) => 1,
);

/// Shops for current page with current filters (for shops list screen).
final shopsPaginatedProvider = FutureProvider.autoDispose<ShopsPage>(
  (ref) {
    final filter = ref.watch(shopsFilterProvider);
    final page = ref.watch(shopsPageProvider);
    final repository = ref.watch(shopsRepositoryProvider);

    // Convert filter state to API params
    final status = filter.status;
    final vehicleType = filter.types.isNotEmpty ? filter.types.join(',') : null;
    final minRating = filter.rating == 'any' ? null : double.tryParse(filter.rating);
    final sort = _mapSortValue(filter.sort);

    return repository.fetchShops(
      page: page,
      pageSize: 10,
      search: filter.query.isEmpty ? null : filter.query,
      status: status,
      vehicleType: vehicleType,
      minRating: minRating,
      sort: sort,
    );
  },
);

/// Single shop detail by id from API (autoDispose so detail screens reset when popped).
final shopDetailProvider =
    FutureProvider.autoDispose.family<Shop, String>((ref, id) async {
  final repository = ref.watch(shopsRepositoryProvider);
  return repository.fetchShopDetail(id);
});

/// Backward compat: single shop by id (tries to find in cached list first).
final shopByIdProvider =
    FutureProvider.autoDispose.family<Shop?, String>((ref, id) async {
  try {
    final shops = await ref.watch(shopsProvider.future);
    return shops.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

/// All holidays.
final holidaysProvider = FutureProvider.autoDispose<List<Holiday>>(
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

/// Map UI sort values to API sort values.
String? _mapSortValue(String uiSort) {
  switch (uiSort) {
    case 'rating':
      return 'rating';
    case 'busy':
      return 'busiest';
    case 'cap':
      return 'capacity';
    default:
      return 'name';
  }
}

// ─── Shop creation ───────────────────────────────────────────────────────────

/// Create a new shop with the provided details.
/// This provider handles the shop creation API call and returns the created shop.
final createShopProvider =
    FutureProvider.family<Shop, ({
      String name,
      String address,
      String pincode,
      String city,
      String state,
      String phone,
      String ownerName,
      String ownerPhone,
      double? latitude,
      double? longitude,
      int? dailyBookingCap,
      List<String>? supportedVehicleTypes,
      String commissionType,
      String? commissionPercentage,
      String? commissionAmount,
      String? commissionFloor,
      String? bankAccountName,
      String? bankAccountNumber,
      String? bankIfsc,
      String? upiId,
      String? gstin,
      String? pan,
    })>(
  (ref, params) {
    final repository = ref.watch(shopsRepositoryProvider);
    return repository.createShop(
      name: params.name,
      address: params.address,
      pincode: params.pincode,
      city: params.city,
      state: params.state,
      phone: params.phone,
      ownerName: params.ownerName,
      ownerPhone: params.ownerPhone,
      latitude: params.latitude,
      longitude: params.longitude,
      dailyBookingCap: params.dailyBookingCap,
      supportedVehicleTypes: params.supportedVehicleTypes,
      commissionType: params.commissionType,
      commissionPercentage: params.commissionPercentage,
      commissionAmount: params.commissionAmount,
      commissionFloor: params.commissionFloor,
      bankAccountName: params.bankAccountName,
      bankAccountNumber: params.bankAccountNumber,
      bankIfsc: params.bankIfsc,
      upiId: params.upiId,
      gstin: params.gstin,
      pan: params.pan,
    );
  },
);

// ─── Shop editing ────────────────────────────────────────────────────────────

/// Applies the Edit Shop form to an existing shop and refreshes what the admin
/// is about to look at — the detail page and the list they came from.
///
/// Fields left null are not sent (PATCH), so the form only overwrites what it
/// actually manages.
final updateShopProvider = Provider<ShopEditor>((ref) => ShopEditor(ref));

class ShopEditor {
  const ShopEditor(this._ref);

  final Ref _ref;

  Future<Shop> call(
    String shopId, {
    String? name,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? phone,
    String? ownerName,
    String? ownerPhone,
    double? latitude,
    double? longitude,
    int? dailyBookingCap,
    List<String>? supportedVehicleTypes,
    String? commissionType,
    String? commissionPercentage,
    String? commissionAmount,
    String? commissionFloor,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
    String? gstin,
    String? pan,
  }) async {
    final updated = await _ref.read(shopsRepositoryProvider).updateShop(
          shopId,
          name: name,
          address: address,
          pincode: pincode,
          city: city,
          state: state,
          phone: phone,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          latitude: latitude,
          longitude: longitude,
          dailyBookingCap: dailyBookingCap,
          supportedVehicleTypes: supportedVehicleTypes,
          commissionType: commissionType,
          commissionPercentage: commissionPercentage,
          commissionAmount: commissionAmount,
          commissionFloor: commissionFloor,
          bankAccountName: bankAccountName,
          bankAccountNumber: bankAccountNumber,
          bankIfsc: bankIfsc,
          upiId: upiId,
          gstin: gstin,
          pan: pan,
        );

    _ref.invalidate(shopByIdProvider(shopId));
    _ref.invalidate(shopDetailProvider(shopId));
    _ref.invalidate(shopsProvider);
    _ref.invalidate(shopsPaginatedProvider);
    return updated;
  }
}

/// Refetches the shops list. Shared by pull-to-refresh and the navigate-back
/// refresh wired up in `app_router.dart`.
Future<void> refreshShops(WidgetRef ref) async {
  ref.invalidate(shopsProvider);
  ref.invalidate(shopsPaginatedProvider);
  await ref.read(shopsPaginatedProvider.future);
}
