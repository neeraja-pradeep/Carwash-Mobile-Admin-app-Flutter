import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../infrastructure/data_sources/local/reviews_local_ds.dart';
import '../../infrastructure/repositories/reviews_repository_impl.dart';
import '../states/reviews_filter_state.dart';

/// Local data source provider (swapped for a remote+cache source in the API phase).
final reviewsLocalDsProvider = Provider<ReviewsLocalDs>(
  (ref) => const ReviewsLocalDs(),
);

/// The reviews repository (domain contract → infrastructure impl).
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepositoryImpl(ref.watch(reviewsLocalDsProvider)),
);

/// All reviews (read). Kept alive so navigation back is instant (warm cache).
final reviewsProvider = FutureProvider<List<Review>>(
  (ref) => ref.watch(reviewsRepositoryProvider).fetchReviews(),
);

/// Temporary UI filter/sort/search state — autoDispose (resets when the list
/// screen is gone).
final reviewsFilterProvider =
    StateNotifierProvider.autoDispose<ReviewsFilterController, ReviewsFilterState>(
  (ref) => ReviewsFilterController(),
);

/// Derived, filtered+sorted reviews (keeps `build` free of logic).
final filteredReviewsProvider =
    Provider.autoDispose<AsyncValue<List<Review>>>((ref) {
  final reviews = ref.watch(reviewsProvider);
  final filter = ref.watch(reviewsFilterProvider);
  return reviews.whenData((list) => applyReviewFilter(list, filter));
});

/// Working copy of the filter while the filter sheet is open (seeded from the
/// committed filter). autoDispose resets it each time the sheet closes.
final reviewsFilterDraftProvider =
    StateProvider.autoDispose<ReviewsFilterState>(
  (ref) => ref.read(reviewsFilterProvider),
);

/// Owns the reviews filter state; all updates produce a new state via copyWith.
class ReviewsFilterController extends StateNotifier<ReviewsFilterState> {
  ReviewsFilterController() : super(const ReviewsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(String value) => state = state.copyWith(sort: value);

  void apply(ReviewsFilterState next) => state = next;

  void reset() => state = const ReviewsFilterState();

  void removeRating() => state = state.copyWith(rating: 'any');

  void removeShop(String shop) => state = state.copyWith(
        shops: state.shops.where((s) => s != shop).toList(),
      );

  void removeHasText() => state = state.copyWith(hasText: false);
}
