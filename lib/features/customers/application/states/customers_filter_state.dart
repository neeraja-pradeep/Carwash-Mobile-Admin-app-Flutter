import '../../domain/entities/customer.dart';

/// Immutable filter/sort/search state for the Customers list. All fields
/// `final`; mutate only through [copyWith].
class CustomersFilterState {
  const CustomersFilterState({
    this.status,
    this.joined = 'any',
    this.volume = 'any',
    this.query = '',
    this.sort = 'name',
  });

  /// `null` = all, `'active'` = non-blocked, `'blocked'` = blocked.
  final String? status;

  /// `'any'` | `'30'` | `'90'` | `'year'` — joined-date range.
  final String joined;

  /// `'any'` | `'lo'` (1–5) | `'mid'` (6–20) | `'hi'` (20+) — booking count.
  final String volume;

  final String query;

  /// `'name'` | `'spend_hi'` | `'bookings_hi'` | `'recent'`.
  final String sort;

  /// Number of active filter chips (drives the Filter pill badge + chip row).
  int get activeCount =>
      (status != null ? 1 : 0) +
      (joined != 'any' ? 1 : 0) +
      (volume != 'any' ? 1 : 0);

  CustomersFilterState copyWith({
    Object? status = _sentinel,
    String? joined,
    String? volume,
    String? query,
    String? sort,
  }) {
    return CustomersFilterState(
      status: status == _sentinel ? this.status : status as String?,
      joined: joined ?? this.joined,
      volume: volume ?? this.volume,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }

  static const Object _sentinel = Object();
}

// ─── Option label maps (matches JSX constants) ───────────────────────────────

/// Joined-range options: `(value, label)`.
const List<(String, String)> kJoinedOpts = [
  ('any', 'Any time'),
  ('30', 'Last 30 days'),
  ('90', 'Last 90 days'),
  ('year', 'This year'),
];

/// Volume options: `(value, label)`.
const List<(String, String)> kVolumeOpts = [
  ('any', 'Any'),
  ('lo', '1–5'),
  ('mid', '6–20'),
  ('hi', '20+'),
];

/// Sort options shown in the sort bottom sheet.
const List<(String, String)> kCustomerSortOpts = [
  ('name', 'Name A–Z'),
  ('spend_hi', 'Spend: high → low'),
  ('bookings_hi', 'Most bookings'),
  ('recent', 'Recently active'),
];

// ─── Pure filter function (application logic, out of widget build) ────────────

/// Applies [f] to [source]: search → status → volume → sort.
List<Customer> applyCustomerFilter(
  List<Customer> source,
  CustomersFilterState f,
) {
  final q = f.query.trim().toLowerCase();

  bool volOk(int n) {
    return switch (f.volume) {
      'lo' => n <= 5,
      'mid' => n >= 6 && n <= 20,
      'hi' => n > 20,
      _ => true,
    };
  }

  final filtered = source.where((c) {
    if (f.status == 'active' && c.blocked) return false;
    if (f.status == 'blocked' && !c.blocked) return false;
    if (!volOk(c.bookings)) return false;
    if (q.isNotEmpty &&
        !c.name.toLowerCase().contains(q) &&
        !c.phone.contains(q)) {
      return false;
    }
    return true;
  }).toList();

  switch (f.sort) {
    case 'spend_hi':
      filtered.sort((a, b) => b.spend.compareTo(a.spend));
    case 'bookings_hi':
      filtered.sort((a, b) => b.bookings.compareTo(a.bookings));
    case 'recent':
      filtered.sort((a, b) => b.lastBooking.compareTo(a.lastBooking));
    default:
      filtered.sort((a, b) => a.name.compareTo(b.name));
  }
  return filtered;
}
