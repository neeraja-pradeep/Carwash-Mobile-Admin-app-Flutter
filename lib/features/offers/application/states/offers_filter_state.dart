/// Immutable filter/sort/search state for the Offers list.
class OffersFilterState {
  const OffersFilterState({
    this.status,
    this.query = '',
    this.sort = 'recent',
  });

  /// Null = all statuses.
  final String? status;
  final String query;

  /// `recent` | `az`
  final String sort;

  int get activeFilterCount => status != null ? 1 : 0;

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
