/// A single entry in the recent activity feed (from `data.jsx` ACTIVITY).
///
/// [iconKey] is one of: `inbox`, `droplet`, `car`, `receipt`, `star`.
class ActivityItem {
  const ActivityItem({
    required this.iconKey,
    required this.text,
    required this.time,
    required this.bookingId,
  });

  /// Semantic icon key used to select the correct [AppIcons] glyph.
  final String iconKey;

  /// Human-readable description of the event.
  final String text;

  /// Relative time string, e.g. "3 min ago".
  final String time;

  /// Associated booking ID for navigation.
  final String bookingId;
}
