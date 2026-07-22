import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../../domain/repositories/offers_repository.dart';
import '../../infrastructure/data_sources/local/offers_local_ds.dart';
import '../../infrastructure/repositories/offers_repository_impl.dart';
import '../states/offers_filter_state.dart';

final _offersLocalDsProvider = Provider<OffersLocalDs>(
  (ref) => const OffersLocalDs(),
);

/// The offers repository (domain contract → infrastructure impl).
final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => OffersRepositoryImpl(ref.watch(_offersLocalDsProvider)),
);

/// Coupons (remote) — driven by the current filter/sort/search state.
///
/// Watches [offersFilterProvider] so search / lifecycle / ordering changes
/// trigger a fresh server fetch. Returns the page of coupons (count is
/// available via [couponCountProvider]).
final couponsProvider = FutureProvider.autoDispose<List<Coupon>>((ref) async {
  final filter = ref.watch(offersFilterProvider);
  final page = await ref.watch(offersRepositoryProvider).fetchCoupons(
        search: filter.query.trim().isEmpty ? null : filter.query.trim(),
        lifecycle: filter.lifecycle,
        ordering: filter.ordering,
      );
  // Stash the count so the list controls can read it without a second fetch.
  ref.read(_couponCountProvider.notifier).state = page.count;
  return page.coupons;
});

final _couponCountProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Total server count for the current coupon query.
final couponCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(_couponCountProvider),
);

/// All banners (local).
final bannersProvider = FutureProvider.autoDispose<List<OfferBanner>>(
  (ref) => ref.watch(offersRepositoryProvider).fetchBanners(),
);

/// Temporary UI filter/sort/search state — autoDispose (resets when screen is gone).
final offersFilterProvider =
    StateNotifierProvider.autoDispose<OffersFilterController, OffersFilterState>(
  (ref) => OffersFilterController(),
);

/// Selected tab — autoDispose.
final offersTabProvider = StateProvider.autoDispose<String>(
  (ref) => 'coupons',
);

/// Owns the offers filter state.
class OffersFilterController extends StateNotifier<OffersFilterState> {
  OffersFilterController() : super(const OffersFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);
  void setSort(String value) => state = state.copyWith(sort: value);
  void setStatus(String? value) => state = state.copyWith(status: value);
  void reset() => state = const OffersFilterState();
}
