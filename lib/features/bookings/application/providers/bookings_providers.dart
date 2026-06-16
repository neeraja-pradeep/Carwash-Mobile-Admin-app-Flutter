import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../../infrastructure/data_sources/local/bookings_local_ds.dart';
import '../../infrastructure/repositories/bookings_repository_impl.dart';
import '../states/bookings_filter_state.dart';

// ── Data layer providers ──────────────────────────────────────────────────────

/// Local data source (swapped for remote+cache in the API phase).
final bookingsLocalDsProvider = Provider<BookingsLocalDs>(
  (ref) => const BookingsLocalDs(),
);

/// The bookings repository (domain contract → infrastructure impl).
final bookingsRepositoryProvider = Provider<BookingsRepository>(
  (ref) => BookingsRepositoryImpl(ref.watch(bookingsLocalDsProvider)),
);

// ── Entity providers ──────────────────────────────────────────────────────────

/// All bookings. Kept alive so navigation back is instant (warm cache).
final bookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.watch(bookingsRepositoryProvider).fetchBookings(),
);

/// Single booking by id (autoDispose — resets when the detail screen closes).
final bookingByIdProvider =
    FutureProvider.autoDispose.family<Booking?, String>((ref, id) async {
  final bookings = await ref.watch(bookingsProvider.future);
  try {
    return bookings.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});

// ── Bookings screen segment ───────────────────────────────────────────────────

/// Tracks which segment is visible: 0 = "Driver & Inspection", 1 = "Carwash".
final bookingsSegmentProvider = StateProvider.autoDispose<int>(
  (ref) => 0,
);

// ── Filter/sort/search state for the Carwash list ────────────────────────────

/// Committed filter state for the Carwash bookings list.
final bookingsFilterProvider =
    StateNotifierProvider.autoDispose<BookingsFilterController,
        BookingsFilterState>(
  (ref) => BookingsFilterController(),
);

/// Working copy of the filter while the filter sheet is open (seeded from the
/// committed filter). autoDispose resets it each time the sheet is closed.
final bookingsFilterDraftProvider =
    StateProvider.autoDispose<BookingsFilterState>(
  (ref) => ref.read(bookingsFilterProvider),
);

/// Derived, filtered+sorted bookings (keeps widget `build` free of logic).
final filteredBookingsProvider =
    Provider.autoDispose<AsyncValue<List<Booking>>>((ref) {
  final bookings = ref.watch(bookingsProvider);
  final filter = ref.watch(bookingsFilterProvider);
  return bookings.whenData((list) => applyBookingsFilter(list, filter));
});

// ── Controller ────────────────────────────────────────────────────────────────

/// Owns the bookings filter state; all updates produce a new state via copyWith.
class BookingsFilterController extends StateNotifier<BookingsFilterState> {
  BookingsFilterController() : super(const BookingsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(String value) => state = state.copyWith(sort: value);

  void apply(BookingsFilterState next) => state = next;

  void reset() => state = const BookingsFilterState();

  void removeDate() => state = state.copyWith(date: 'today');

  void removeDaypart() => state = state.copyWith(daypart: null);

  void removeStatus(String key) => state = state.copyWith(
        statuses: state.statuses.where((s) => s != key).toList(),
      );

  void removeShop(String shopId) => state = state.copyWith(
        shops: state.shops.where((s) => s != shopId).toList(),
      );

  void removeAssign() => state = state.copyWith(assign: null);
}
