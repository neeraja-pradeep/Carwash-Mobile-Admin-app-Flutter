import 'badge_tone.dart';

/// Car-wash booking lifecycle states (9 stages + cancelled).
///
/// Wire-key mapping keeps the API contract stable while avoiding the reserved
/// word `new` (the `created` value carries the wire key `"new"`).
enum BookingStatus {
  created,
  assigned,
  going,
  picked,
  atShop,
  washing,
  done,
  returning,
  completed,
  cancelled,
  pending,
  refundRequested,
  refunded,
}

/// Display label, badge tone and wire-key for a [BookingStatus].
extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.created => 'New',
        BookingStatus.assigned => 'Assigned',
        BookingStatus.going => 'Going',
        BookingStatus.picked => 'Picked',
        BookingStatus.atShop => 'At Shop',
        BookingStatus.washing => 'Washing',
        BookingStatus.done => 'Done',
        BookingStatus.returning => 'Returning',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.pending => 'Pending',
        BookingStatus.refundRequested => 'Refund Requested',
        BookingStatus.refunded => 'Refunded',
      };

  BadgeTone get tone => switch (this) {
        BookingStatus.created => BadgeTone.amber,
        BookingStatus.completed => BadgeTone.green,
        BookingStatus.cancelled => BadgeTone.red,
        _ => BadgeTone.blue,
      };

  String get key => switch (this) {
        BookingStatus.created => 'new',
        BookingStatus.atShop => 'atshop',
        _ => name,
      };

  /// Sequential index within the forward flow (excludes `cancelled`).
  int get order => BookingStatus.values.indexOf(this);
}

/// Forward lifecycle order used by the inline status-update block.
const List<BookingStatus> kBookingStatusOrder = [
  BookingStatus.created,
  BookingStatus.assigned,
  BookingStatus.going,
  BookingStatus.picked,
  BookingStatus.atShop,
  BookingStatus.washing,
  BookingStatus.done,
  BookingStatus.returning,
  BookingStatus.completed,
];

/// Resolves a wire-key (e.g. from sample data or an API) to a [BookingStatus].
BookingStatus bookingStatusFromKey(String key) {
  return switch (key) {
    'new' => BookingStatus.created,
    'atshop' => BookingStatus.atShop,
    _ => BookingStatus.values.firstWhere(
        (s) => s.name == key,
        orElse: () => BookingStatus.created,
      ),
  };
}
