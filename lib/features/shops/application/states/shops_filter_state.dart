import '../../domain/entities/shop.dart';

/// Immutable filter/sort/search state for the Shops list.
/// All fields `final`; mutate only through [copyWith].
class ShopsFilterState {
  const ShopsFilterState({
    this.query = '',
    this.status,
    this.types = const [],
    this.rating = 'any',
    this.sort = 'name',
  });

  /// Free-text search (shop name or area).
  final String query;

  /// `null` = all, `'active'` or `'inactive'`.
  final String? status;

  /// Vehicle types that must all be present (empty = all).
  final List<String> types;

  /// `'any'` | `'4.5'` | `'4.0'` | `'3.5'`.
  final String rating;

  /// `'name'` | `'rating'` | `'busy'` | `'cap'`.
  final String sort;

  /// Count of active filters (drives the filter button badge).
  int get activeCount =>
      (status != null ? 1 : 0) +
      types.length +
      (rating != 'any' ? 1 : 0);

  ShopsFilterState copyWith({
    String? query,
    Object? status = _sentinel,
    List<String>? types,
    String? rating,
    String? sort,
  }) {
    return ShopsFilterState(
      query: query ?? this.query,
      status: status == _sentinel ? this.status : status as String?,
      types: types ?? this.types,
      rating: rating ?? this.rating,
      sort: sort ?? this.sort,
    );
  }
}

/// Sentinel used by [ShopsFilterState.copyWith] to distinguish
/// "not provided" from `null` for the nullable [status] field.
const Object _sentinel = Object();

/// Applies a [ShopsFilterState] to a shop list (search → filters → sort).
/// Lives in the application layer so the widget `build` stays free of logic.
List<Shop> applyShopsFilter(List<Shop> source, ShopsFilterState f) {
  final q = f.query.trim().toLowerCase();

  final filtered = source.where((s) {
    if (f.status == 'active' && !s.active) return false;
    if (f.status == 'inactive' && s.active) return false;
    if (f.types.isNotEmpty &&
        !f.types.any((t) => s.vehicleTypes.contains(t))) {
      return false;
    }
    if (f.rating != 'any') {
      final minRating = double.tryParse(f.rating) ?? 0;
      if (s.rating < minRating) return false;
    }
    if (q.isNotEmpty &&
        !s.name.toLowerCase().contains(q) &&
        !s.area.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }).toList();

  switch (f.sort) {
    case 'rating':
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    case 'busy':
      filtered.sort((a, b) => b.todayBookings.compareTo(a.todayBookings));
    case 'cap':
      filtered.sort((a, b) {
        final ra = a.cap > 0 ? a.todayBookings / a.cap : 0.0;
        final rb = b.cap > 0 ? b.todayBookings / b.cap : 0.0;
        return rb.compareTo(ra);
      });
    default: // 'name'
      filtered.sort((a, b) => a.name.compareTo(b.name));
  }

  return filtered;
}
