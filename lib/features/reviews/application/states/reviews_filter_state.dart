/// Immutable filter/sort/search state for the Reviews list. All fields `final`;
/// mutate only through [copyWith].
class ReviewsFilterState {
  const ReviewsFilterState({
    this.rating = 'any',
    this.hasText = false,
    this.date = 'any',
    this.query = '',
    this.sort = 'recent',
  });

  /// `any` | `5` | `4` | `3` (n-star and up).
  final String rating;
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
      (rating != 'any' ? 1 : 0) + (hasText ? 1 : 0) + (date != 'any' ? 1 : 0);

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
    bool? hasText,
    String? date,
    String? query,
    String? sort,
  }) {
    return ReviewsFilterState(
      rating: rating ?? this.rating,
      hasText: hasText ?? this.hasText,
      date: date ?? this.date,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}
