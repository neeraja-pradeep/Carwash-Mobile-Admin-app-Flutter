import '../../../../core/status/booking_status.dart';

/// Immutable filter/sort/search state for the Carwash Bookings list.
/// All fields `final`; mutate only through [copyWith].
class BookingsFilterState {
  const BookingsFilterState({
    this.date = 'today',
    this.daypart,
    this.statuses = const [],
    this.shops = const [],
    this.assign,
    this.query = '',
    this.sort = 'recent',
  });

  /// `today` | `yesterday` | `last7` | `month` | `custom`
  final String date;

  /// `morning` | `afternoon` | `evening` | null (any)
  final String? daypart;

  /// Selected [BookingStatus] keys (empty = all).
  final List<String> statuses;

  /// Selected shop ids (empty = all).
  final List<String> shops;

  /// `me` | `cofounder` | `unassigned` | null (any)
  final String? assign;

  final String query;

  /// `recent` | `oldest` | `amount_hi` | `amount_lo` | `name`
  final String sort;

  /// Count of active filter chips (drives Filter pill badge).
  int get activeCount =>
      (date != 'today' ? 1 : 0) +
      (daypart != null ? 1 : 0) +
      statuses.length +
      shops.length +
      (assign != null ? 1 : 0);

  BookingsFilterState copyWith({
    String? date,
    Object? daypart = _sentinel,
    List<String>? statuses,
    List<String>? shops,
    Object? assign = _sentinel,
    String? query,
    String? sort,
  }) {
    return BookingsFilterState(
      date: date ?? this.date,
      daypart: daypart == _sentinel ? this.daypart : daypart as String?,
      statuses: statuses ?? this.statuses,
      shops: shops ?? this.shops,
      assign: assign == _sentinel ? this.assign : assign as String?,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

/// Sentinel for nullable copyWith fields.
const Object _sentinel = Object();

/// Applies [BookingsFilterState] to a booking list (filtering and sorting
/// are already done by the API, so this just returns the list as-is).
List<T> applyBookingsFilter<T>(List<T> source, BookingsFilterState f) {
  // The API handles all filtering and sorting based on the query parameters
  // we pass in the provider. This function just passes through the results.
  return source;
}
