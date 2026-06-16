import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A promotional banner displayed in the customer app.
///
/// Named [OfferBanner] to avoid collision with Flutter's [Banner] widget.
class OfferBanner {
  const OfferBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.placement,
    required this.link,
    required this.order,
    required this.image,
    required this.start,
    required this.end,
    required this.impressions,
    required this.taps,
  });

  final String id;
  final String title;
  final String subtitle;
  /// `active` | `scheduled` | `inactive`
  final String status;
  final String placement;
  final String link;
  final int order;
  final String image;
  final String start;
  final String end;
  final int impressions;
  final int taps;

  /// Status label and badge tone.
  (String label, BadgeTone tone) get statusDisplay => switch (status) {
        'active' => ('Active', BadgeTone.green),
        'scheduled' => ('Scheduled', BadgeTone.blue),
        _ => ('Inactive', BadgeTone.grey),
      };
}
