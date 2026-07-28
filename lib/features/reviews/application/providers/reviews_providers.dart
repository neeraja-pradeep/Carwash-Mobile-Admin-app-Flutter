import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../infrastructure/repositories/reviews_repository_impl.dart';
import '../states/reviews_filter_state.dart';

/// The reviews repository (domain contract → infrastructure impl).
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepositoryImpl(),
);

/// Reviews list page (server-side filtered/sorted). Re-fetches whenever the
/// committed filter changes. autoDispose so it resets when the screen is gone.
final reviewsProvider = FutureProvider.autoDispose<ReviewsPage>((ref) {
  final filter = ref.watch(reviewsFilterProvider);
  return ref.watch(reviewsRepositoryProvider).fetchReviews(
        search: filter.query.trim().isEmpty ? null : filter.query.trim(),
        rating: _ratingParam(filter.rating),
        date: _dateParam(filter.date),
        hasComment: filter.hasText ? true : null,
        sort: _sortParam(filter.sort),
      );
});

/// Temporary UI filter/sort/search state — autoDispose (resets when the list
/// screen is gone).
final reviewsFilterProvider =
    StateNotifierProvider.autoDispose<ReviewsFilterController, ReviewsFilterState>(
  (ref) => ReviewsFilterController(),
);

/// Derived, filtered reviews. The server handles search/rating/date/has_comment/
/// sort; the shop chips (selected by name, multi-select) are applied here since
/// the API only filters by a single shop id.
final filteredReviewsProvider =
    Provider.autoDispose<AsyncValue<List<Review>>>((ref) {
  final page = ref.watch(reviewsProvider);
  final filter = ref.watch(reviewsFilterProvider);
  return page.whenData((p) {
    if (filter.shops.isEmpty) return p.reviews;
    return p.reviews.where((r) => filter.shops.contains(r.shop)).toList();
  });
});

/// Single review detail (full record from the detail endpoint).
final reviewDetailProvider =
    FutureProvider.autoDispose.family<Review?, String>((ref, id) {
  return ref.watch(reviewsRepositoryProvider).fetchReviewDetail(id);
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

  /// `7` | `30` | `any` — also the escape hatch from an empty recent window.
  void setDate(String value) => state = state.copyWith(date: value);

  void apply(ReviewsFilterState next) => state = next;

  void reset() => state = const ReviewsFilterState();

  void removeRating() => state = state.copyWith(rating: 'any');

  void removeShop(String shop) => state = state.copyWith(
        shops: state.shops.where((s) => s != shop).toList(),
      );

  void removeHasText() => state = state.copyWith(hasText: false);
}

/// Maps the UI rating value to the API `rating` enum (`any` → no filter).
String? _ratingParam(String rating) => rating == 'any' ? null : rating;

/// Maps the UI date value (`7`/`30`/`any`) to the API `date` enum
/// (`7d`/`30d`/`all`). Always sent explicitly because the API defaults to 7d.
String _dateParam(String date) {
  switch (date) {
    case '30':
      return '30d';
    case 'any':
      return 'all';
    case '7':
    default:
      return '7d';
  }
}

/// Maps the UI sort value to the API `sort` enum.
String _sortParam(String sort) {
  switch (sort) {
    case 'rating_hi':
      return 'rating_desc';
    case 'rating_lo':
      return 'rating_asc';
    case 'recent':
    default:
      return 'recent';
  }
}

/// Refetches the reviews list. Shared by pull-to-refresh and the navigate-back
/// refresh wired up in `app_router.dart`.
Future<void> refreshReviews(WidgetRef ref) async {
  ref.invalidate(reviewsProvider);
  await ref.read(reviewsProvider.future);
}
