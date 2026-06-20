/// A single entry in the recent activity feed.
///
/// [iconKey] is one of: `inbox`, `droplet`, `car`, `receipt`, `star`, `users`, `search`, `nav`.
class ActivityItem {
  const ActivityItem({
    required this.iconKey,
    required this.text,
    required this.time,
    required this.bookingId,
    this.verb,
    this.title,
    this.subtitle,
    this.reference,
    this.isBooking = true,
  });

  /// Semantic icon key used to select the correct [AppIcons] glyph.
  final String iconKey;

  /// Human-readable description of the event (generated from title + subtitle).
  final String text;

  /// Relative time string, e.g. "3 min ago".
  final String time;

  /// Associated booking/DI booking ID for navigation.
  final String bookingId;

  /// API verb value (booking_created, wash_done, etc).
  final String? verb;

  /// API title field.
  final String? title;

  /// API subtitle field (shop or reference).
  final String? subtitle;

  /// Human-readable reference (CW-xxx or SR-DR-xxx).
  final String? reference;

  /// True if this is a booking, false if DI booking.
  final bool isBooking;
}
