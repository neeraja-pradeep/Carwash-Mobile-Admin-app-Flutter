import '../../domain/entities/booking.dart';
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

/// Applies [BookingsFilterState] to a booking list (filter then sort).
List<Booking> applyBookingsFilter(List<Booking> source, BookingsFilterState f) {
  final q = f.query.trim().toLowerCase();

  final filtered = source.where((b) {
    // Date: "yesterday" → empty (all sample data is "today")
    if (f.date == 'yesterday') return false;

    // Daypart filter
    if (f.daypart != null && !_inDaypart(b.pickup.time, f.daypart!)) {
      return false;
    }

    // Status multi-select
    if (f.statuses.isNotEmpty && !f.statuses.contains(b.status.key)) {
      return false;
    }

    // Shop multi-select
    if (f.shops.isNotEmpty && !f.shops.contains(b.shopId)) return false;

    // Assignment
    if (f.assign == 'me' && b.driverId != 'd1') return false;
    if (f.assign == 'cofounder' && b.driverId != 'd2') return false;
    if (f.assign == 'unassigned' && b.driverId != null) return false;

    // Search
    if (q.isNotEmpty) {
      final matchId = b.id.toLowerCase().contains(q);
      final matchName = b.customer.name.toLowerCase().contains(q);
      final matchPhone = b.customer.phone.contains(q);
      if (!matchId && !matchName && !matchPhone) return false;
    }

    return true;
  }).toList();

  switch (f.sort) {
    case 'oldest':
      filtered.sort((a, b) => a.id.compareTo(b.id));
    case 'amount_hi':
      filtered.sort((a, b) => b.total.compareTo(a.total));
    case 'amount_lo':
      filtered.sort((a, b) => a.total.compareTo(b.total));
    case 'name':
      filtered.sort((a, b) => a.customer.name.compareTo(b.customer.name));
    default: // recent
      filtered.sort((a, b) => b.id.compareTo(a.id));
  }

  return filtered;
}

/// Returns true if the pickup time string falls in the [daypart] window.
bool _inDaypart(String time, String daypart) {
  final h = _hourOf(time);
  switch (daypart) {
    case 'morning':
      return h >= 5 && h < 12;
    case 'afternoon':
      return h >= 12 && h < 17;
    case 'evening':
      return h >= 17 && h < 21;
    default:
      return true;
  }
}

int _hourOf(String t) {
  final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
      .firstMatch(t);
  if (m == null) return 12;
  int h = int.parse(m.group(1)!) % 12;
  if (m.group(3)!.toUpperCase() == 'PM') h += 12;
  return h;
}
