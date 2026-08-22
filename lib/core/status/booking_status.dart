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

/// Wire values of the API's `washing_status` field, which tracks crew progress
/// through the job. Its vocabulary is separate from `status` and does not match
/// the enum names, so it needs its own table.
///
/// The API's ladder is `confirmed → crew_en_route → picked_up →
/// dropped_at_shop → in_progress → wash_done → picked_up_from_shop → returning
/// → completed`. `confirmed` is deliberately absent: it is the state every
/// booking starts in and carries no crew progress, so letting it match would
/// report an assigned booking as "New".
const Map<String, BookingStatus> kWashingStatusKeys = {
  'crew_en_route': BookingStatus.going,
  'picked_up': BookingStatus.picked,
  'dropped_at_shop': BookingStatus.atShop,
  'in_progress': BookingStatus.washing,
  'wash_done': BookingStatus.done,
  'picked_up_from_shop': BookingStatus.returning,
  'returning': BookingStatus.returning,
  'completed': BookingStatus.completed,
};

/// The `washing_status` value to PATCH when advancing a car-wash booking to a
/// stage — the reverse of [kWashingStatusKeys], which cannot be derived because
/// two API stages collapse onto [BookingStatus.returning].
///
/// `assigned` has no entry: the API models assignment through its own endpoint,
/// not the wash ladder.
const Map<BookingStatus, String> kWashingStatusWireKeys = {
  BookingStatus.created: 'confirmed',
  BookingStatus.going: 'crew_en_route',
  BookingStatus.picked: 'picked_up',
  BookingStatus.atShop: 'dropped_at_shop',
  BookingStatus.washing: 'in_progress',
  BookingStatus.done: 'wash_done',
  BookingStatus.returning: 'picked_up_from_shop',
  BookingStatus.completed: 'completed',
};

/// The status to show for a car-wash booking, given both status fields.
///
/// A booking carries two: `status` is the booking-level state, while
/// `washing_status` is what the driver app advances as it works the job. A
/// driver finishing a wash sets `washing_status` to `completed` and leaves
/// `status` alone, so reading `status` by itself leaves the admin app showing
/// "Assigned" for work that is already done. `washing_status` therefore wins
/// whenever it is set.
BookingStatus resolveBookingStatus({
  String? status,
  String? washingStatus,
  bool hasAssignee = false,
}) {
  // Terminal money states outrank crew progress: a refunded booking that got as
  // far as `wash_done` is a refund, not a "Done" job.
  if (status == 'cancelled') return BookingStatus.cancelled;
  if (status == 'refunded') return BookingStatus.refunded;
  if (status == 'refund_requested') return BookingStatus.refundRequested;

  final fromWashing = kWashingStatusKeys[washingStatus];
  if (fromWashing != null) return fromWashing;

  // No crew progress recorded yet — fall back to the booking-level state.
  if (status == 'completed') return BookingStatus.completed;
  if (hasAssignee) return BookingStatus.assigned;
  return (status == null || status.isEmpty)
      ? BookingStatus.created
      : bookingStatusFromKey(status);
}

/// Resolves a timeline entry's key to a [BookingStatus].
///
/// Timeline entries carry the `washing_status` vocabulary (`crew_en_route`,
/// `wash_done`, …), which does not match the enum names — running them through
/// [bookingStatusFromKey] alone collapses every entry to `created`. Entries
/// outside that vocabulary (the booking-level `confirmed`, say) still fall back
/// to the enum-name lookup.
BookingStatus washingStatusFromKey(String? key) =>
    kWashingStatusKeys[key] ?? bookingStatusFromKey(key ?? '');

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
