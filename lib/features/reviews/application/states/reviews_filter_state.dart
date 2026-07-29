import '../../domain/entities/review.dart';

/// Immutable filter/sort/search state for the Reviews list. All fields `final`;
/// mutate only through [copyWith].
class ReviewsFilterState {
  const ReviewsFilterState({
    this.rating = 'any',
    this.shops = const [],
    this.hasText = false,
    this.date = 'any',
    this.query = '',
    this.sort = 'recent',
  });

  /// `any` | `5` | `4` | `3` (n-star and up).
  final String rating;

  /// Selected shop names (empty = all).
  final List<String> shops;
  final bool hasText;

  /// `7` | `30` | `any` — window on `created_at`, mapped to the API's
  /// `7d`/`30d`/`all`. Defaults to `any`: the API's own default is `7d`, which
  /// silently hid every older review before an admin had chosen anything.
  final String date;
  final String query;

  /// `recent` | `rating_hi` | `rating_lo`.
  final String sort;

  /// Count of active filters (drives the Filter pill badge + chip row).
  /// [date] counts like any other chip once it narrows off the default.
  int get activeCount =>
      (rating != 'any' ? 1 : 0) +
      shops.length +
      (hasText ? 1 : 0) +
      (date != 'any' ? 1 : 0);

  /// Human label for the selected window — chip row and top bar subtitle.
  String get dateLabel => switch (date) {
        '7' => 'Last 7 days',
        '30' => 'Last 30 days',
        _ => 'All time',
      };

  /// True when the admin has actually narrowed the list themselves.
  bool get hasUserFilter => activeCount > 0 || query.trim().isNotEmpty;

  ReviewsFilterState copyWith({
    String? rating,
    List<String>? shops,
    bool? hasText,
    String? date,
    String? query,
    String? sort,
  }) {
    return ReviewsFilterState(
      rating: rating ?? this.rating,
      shops: shops ?? this.shops,
      hasText: hasText ?? this.hasText,
      date: date ?? this.date,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

/// Applies a [ReviewsFilterState] to a review list (search → filters → sort).
/// Lives in the application layer so the widget `build` stays free of logic.
List<Review> applyReviewFilter(List<Review> source, ReviewsFilterState f) {
  final q = f.query.trim().toLowerCase();
  final filtered = source.where((r) {
    if (f.rating == '5' && r.rating != 5) return false;
    if (f.rating == '4' && r.rating < 4) return false;
    if (f.rating == '3' && r.rating < 3) return false;
    if (f.shops.isNotEmpty && !f.shops.contains(r.shop)) return false;
    if (f.hasText && !r.hasText) return false;
    if (q.isNotEmpty &&
        !r.customer.toLowerCase().contains(q) &&
        !r.shop.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }).toList();

  switch (f.sort) {
    case 'rating_hi':
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    case 'rating_lo':
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
    default:
      break; // recent = original order
  }
  return filtered;
}
