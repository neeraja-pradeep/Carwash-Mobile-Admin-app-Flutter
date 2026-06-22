import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/booking.dart';
import '../../domain/entities/carwash_booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../../infrastructure/data_sources/local/bookings_local_ds.dart';
import '../../infrastructure/repositories/bookings_repository_impl.dart';
import '../../infrastructure/models/booking_detail_response_model.dart' as detail_models;
import '../../infrastructure/models/refund_response_model.dart';
import '../../../../core/status/booking_status.dart';
import '../../../../core/status/payment_status.dart';
import '../states/bookings_filter_state.dart';

// ── Data layer providers ──────────────────────────────────────────────────────

/// Local data source for detail screen bookings (keeps old Booking entity).
final bookingsLocalDsProvider = Provider<BookingsLocalDs>(
  (ref) => const BookingsLocalDs(),
);

/// The bookings repository (domain contract → infrastructure impl).
final bookingsRepositoryProvider = Provider<BookingsRepository>(
  (ref) => BookingsRepositoryImpl(),
);

// ── Entity providers ──────────────────────────────────────────────────────────

/// All carwash bookings with automatic caching per query.
final bookingsProvider = FutureProvider<List<CarwashBooking>>(
  (ref) {
    final filter = ref.watch(bookingsFilterProvider);

    // Map filter.date to API date_range parameter
    String? dateRange;
    if (filter.date != 'today') {
      dateRange = switch (filter.date) {
        'yesterday' => 'yesterday',
        'last7' => 'last_7_days',
        'month' => 'this_month',
        _ => null,
      };
    }

    return ref.watch(bookingsRepositoryProvider).fetchBookings(
          search: filter.query.isNotEmpty ? filter.query : null,
          dateRange: dateRange,
          timeOfDay: filter.daypart,
          statusChips: filter.statuses.isNotEmpty ? filter.statuses : null,
          shops: filter.shops.isNotEmpty ? filter.shops : null,
          assignment: filter.assign,
          sort: filter.sort,
        );
  },
);

/// Single carwash booking by int id (for list navigation - autoDispose).
final carwashBookingByIdProvider =
    FutureProvider.autoDispose.family<CarwashBooking?, int>((ref, id) async {
  final bookings = await ref.watch(bookingsProvider.future);
  try {
    return bookings.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});

/// Single booking by string id (for detail screen - tries API first, falls back to local).
final bookingByIdProvider =
    FutureProvider.autoDispose.family<Booking?, String>((ref, id) async {
  // Try to parse as int for API
  final intId = int.tryParse(id);

  // Try API first if it's a valid int
  if (intId != null) {
    try {
      debugPrint('📱 Fetching booking detail from API for ID: $intId');
      final detail = await ref
          .watch(bookingsRepositoryProvider)
          .getBookingDetail(intId);
      debugPrint('✅ Successfully fetched booking detail from API');
      debugPrint('📋 Driver Info: ${detail.driver?.name ?? "No driver assigned"}');
      // Create a Booking from detail_models.BookingDetailResponse for compatibility
      return _bookingFromDetail(detail);
    } catch (e) {
      debugPrint('❌ API detail fetch failed: $e, trying local data source');
    }
  }

  // Fall back to local data source
  try {
    debugPrint('📖 Fetching booking from local data source');
    final bookings = await ref.watch(bookingsLocalDsProvider).fetchBookings();
    return bookings.firstWhere((b) => b.id == id);
  } catch (e) {
    debugPrint('❌ Local data source fetch failed: $e');
    return null;
  }
});

/// Format time string from "12:00:00" to "12:00 PM"
String _formatTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';
  try {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  } catch (e) {
    return timeStr;
  }
}

/// Parse vehicle label "Make Model · Plate" into parts
Vehicle _parseVehicleLabel(String? label) {
  if (label == null || label.isEmpty) {
    return const Vehicle(
      make: 'Unknown',
      model: 'Unknown',
      type: 'Car',
      plate: null,
    );
  }

  try {
    // Label format: "Hyundai Verna · KL-04-XX-1234"
    final parts = label.split('·').map((s) => s.trim()).toList();
    if (parts.length == 2) {
      final nameParts = parts[0].split(' ');
      return Vehicle(
        make: nameParts.isNotEmpty ? nameParts[0] : 'Unknown',
        model: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        type: 'Car',
        plate: parts[1],
      );
    }
  } catch (e) {
    debugPrint('Error parsing vehicle label: $e');
  }

  return const Vehicle(
    make: 'Unknown',
    model: 'Unknown',
    type: 'Car',
    plate: null,
  );
}

/// Parse amount from string, handling decimals
int _parseAmount(String? amountStr) {
  if (amountStr == null || amountStr.isEmpty) return 0;
  try {
    final amount = double.parse(amountStr);
    return amount.toInt();
  } catch (e) {
    return 0;
  }
}

/// Convert detail_models.BookingDetailResponse to Booking entity for compatibility
Booking _bookingFromDetail(detail_models.BookingDetailResponse detail) {
  // Parse actual status from API response
  final status = bookingStatusFromKey(detail.status);

  return Booking(
    id: detail.id.toString(),
    status: status,
    customer: BookingParty(
      name: detail.customerName ?? 'Unknown',
      phone: detail.customerPhone ?? '',
    ),
    vehicle: _parseVehicleLabel(detail.vehicleLabel),
    pickup: RoutePoint(
      address: detail.addressDetail?.address ?? '',
      time: _formatTime(detail.startSlotTime),
    ),
    drop: RoutePoint(
      address: detail.dropAddress ?? '',
      time: '',
      sameAsPickup: detail.dropAddress == null,
    ),
    shopId: detail.shop?.id.toString() ?? '',
    services: detail.services
            ?.map((s) => BookingService(
                  name: s.name,
                  price: 0,
                  minutes: s.estimatedMinutes ?? 0,
                ))
            .toList() ??
        [],
    total: _parseAmount(detail.amount),
    payment: _parsePaymentStatus(detail.paymentStatus),
    createdAt: '',
    timeline: detail.timeline
            ?.map((t) => TimelineEntry(
                  status: bookingStatusFromKey(t.washingStatus ?? ''),
                  at: t.createdAt ?? '',
                  by: t.actor ?? '',
                ))
            .toList() ??
        [],
    damage: const DamageReport(),
    driverId: detail.driver?.id.toString(),
    assigneeName: detail.driver?.name,
  );
}

/// Parse payment status from API string response
PaymentStatus _parsePaymentStatus(String? status) {
  if (status == null || status.isEmpty) return PaymentStatus.pending;
  return switch (status.toLowerCase()) {
    'paid' => PaymentStatus.paid,
    'refunded' => PaymentStatus.refunded,
    'pending' => PaymentStatus.pending,
    _ => PaymentStatus.pending,
  };
}

// ── Detail screen providers ──────────────────────────────────────────────

/// Get full booking detail (autoDispose - resets when detail screen closes)
final bookingDetailProvider =
    FutureProvider.autoDispose.family<detail_models.BookingDetailResponse, int>((ref, id) {
  return ref.watch(bookingsRepositoryProvider).getBookingDetail(id);
});

/// Get assignable drivers for a booking
final assignableDriversProvider =
    FutureProvider.autoDispose.family<detail_models.AssignableDriversResponse, int>(
        (ref, id) {
  return ref.watch(bookingsRepositoryProvider).getAssignableDrivers(id);
});

// ── Bookings screen segment ───────────────────────────────────────────────────

/// Tracks which segment is visible: 0 = "Driver & Inspection" (default), 1 =
/// "Carwash".
///
/// Session-scoped (NOT autoDispose) so the selected segment survives detail
/// round-trips and tab switches — it only resets to the default on a fresh app
/// launch, mirroring the JSX `keep` ref. See INTENT.md §3 (state preservation).
final bookingsSegmentProvider = StateProvider<int>(
  (ref) => 0,
);

// ── Filter/sort/search state for the Carwash list ────────────────────────────

/// Committed filter state for the Carwash bookings list.
///
/// Session-scoped (NOT autoDispose): search, filters, sort and the default-to-
/// today date must be preserved when returning from the booking detail or when
/// switching bottom-nav tabs. A fresh launch starts from [BookingsFilterState]'s
/// defaults (date = today).
final bookingsFilterProvider =
    StateNotifierProvider<BookingsFilterController, BookingsFilterState>(
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
    Provider.autoDispose<AsyncValue<List<CarwashBooking>>>((ref) {
  final bookings = ref.watch(bookingsProvider);
  final filter = ref.watch(bookingsFilterProvider);
  return bookings.whenData((list) => applyBookingsFilter(list, filter));
});

// ── Refund providers ──────────────────────────────────────────────────────────

/// Fetch refund summary for a booking (pre-fill data and refund history)
final refundSummaryProvider =
    FutureProvider.autoDispose.family<RefundSummaryResponse, int>((ref, bookingId) {
  return ref.watch(bookingsRepositoryProvider).getRefundSummary(bookingId);
});

/// Create a refund for a booking
final createRefundProvider =
    FutureProvider.autoDispose.family<RefundResponse, (int, int?, int?, String?, String?)>(
  (ref, args) {
    final (bookingId, percent, amount, reason, comment) = args;
    return ref.watch(bookingsRepositoryProvider).createRefund(
          bookingId,
          percent: percent,
          amount: amount,
          reason: reason,
          comment: comment,
        );
  },
);

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
