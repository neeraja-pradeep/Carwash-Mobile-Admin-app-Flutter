/// Immutable filter/sort/search state for the Offers list.
class OffersFilterState {
  const OffersFilterState({
    this.status,
    this.query = '',
    this.sort = 'recent',
  });

  /// Null = all statuses. One of the lifecycle keys:
  /// `active` · `scheduled` · `paused` · `expired`.
  final String? status;
  final String query;

  /// `recent` | `az`
  final String sort;

  int get activeFilterCount => status != null ? 1 : 0;

  /// Maps [sort] to the API `ordering` param.
  String get ordering => sort == 'az' ? 'name' : '-created_at';

  /// Maps [status] to the API `lifecycle` param (csv); null when "all".
  String? get lifecycle => status;

  /// The banners endpoint orders by `display_order` by default and has no
  /// `name` field — "A–Z" has nothing to sort on, so it falls back to the
  /// designed default rather than sending something the server would reject.
  String get bannerOrdering =>
      sort == 'recent' ? '-created_at' : 'display_order';

  /// Promotions call a switched-off banner `inactive` where coupons say
  /// `paused`; every other chip shares the coupon vocabulary.
  String? get bannerLifecycle => switch (status) {
        null => null,
        'paused' => 'inactive',
        final s => s,
      };

  OffersFilterState copyWith({
    Object? status = _sentinel,
    String? query,
    String? sort,
  }) {
    return OffersFilterState(
      status: status == _sentinel ? this.status : status as String?,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

const _sentinel = Object();
