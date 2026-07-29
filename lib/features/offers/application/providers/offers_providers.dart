import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../../domain/repositories/offers_repository.dart';
import '../../infrastructure/repositories/offers_repository_impl.dart';
import '../states/offers_filter_state.dart';

/// The offers repository (domain contract → infrastructure impl).
final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => OffersRepositoryImpl(),
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

/// Banners (remote) — driven by the same filter/sort/search state as coupons.
///
/// The Banners tab's status chips share the coupon lifecycle vocabulary except
/// for `paused`, which promotions call `inactive`; anything the promotions
/// endpoint would reject is dropped rather than sent.
final bannersProvider = FutureProvider.autoDispose<List<OfferBanner>>(
  (ref) async {
    final filter = ref.watch(offersFilterProvider);
    final page = await ref.watch(offersRepositoryProvider).fetchBanners(
          search: filter.query.trim().isEmpty ? null : filter.query.trim(),
          lifecycle: filter.bannerLifecycle,
          ordering: filter.bannerOrdering,
        );
    ref.read(_bannerCountProvider.notifier).state = page.count;
    return page.banners;
  },
);

final _bannerCountProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Total server count for the current banner query.
final bannerCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(_bannerCountProvider),
);

/// Create / update / delete for banners. Each call refetches the list so the
/// tab reflects the server rather than a locally patched copy.
class BannerActions {
  const BannerActions(this._ref);

  final Ref _ref;

  OffersRepository get _repo => _ref.read(offersRepositoryProvider);

  Future<OfferBanner> create(
    Map<String, dynamic> body, {
    String? imagePath,
  }) async {
    final banner = await _repo.createBanner(body, imagePath: imagePath);
    _ref.invalidate(bannersProvider);
    return banner;
  }

  Future<OfferBanner> update(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage = false,
  }) async {
    final banner = await _repo.updateBanner(
      id,
      body,
      imagePath: imagePath,
      removeImage: removeImage,
    );
    _ref.invalidate(bannersProvider);
    return banner;
  }

  Future<void> delete(String id) async {
    await _repo.deleteBanner(id);
    _ref.invalidate(bannersProvider);
  }
}

final bannerActionsProvider =
    Provider<BannerActions>((ref) => BannerActions(ref));

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

/// Refetches both offers tabs. Shared by pull-to-refresh and the navigate-back
/// refresh wired up in `app_router.dart`.
Future<void> refreshOffers(WidgetRef ref) async {
  ref.invalidate(couponsProvider);
  ref.invalidate(bannersProvider);
  await ref.read(couponsProvider.future);
}
