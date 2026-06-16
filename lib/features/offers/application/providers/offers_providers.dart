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

/// All coupons.
final couponsProvider = FutureProvider<List<Coupon>>(
  (ref) => ref.watch(offersRepositoryProvider).fetchCoupons(),
);

/// All banners.
final bannersProvider = FutureProvider<List<OfferBanner>>(
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
