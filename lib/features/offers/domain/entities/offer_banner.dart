import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A promotional banner shown on the customer Home screen.
///
/// Mirrors the API's `Promotion` (`/api/shop/v1/promotions/`). Named
/// [OfferBanner] to avoid collision with Flutter's [Banner] widget.
class OfferBanner {
  const OfferBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.placement,
    required this.isActive,
    required this.displayOrder,
    required this.lifecycleStatus,
    required this.impressionCount,
    required this.tapCount,
    this.imageUrl,
    this.deepLink,
    this.couponId,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Pill text on the card, e.g. `SPECIAL OFFER`.
  final String badgeText;

  /// `home_hero` | `home_strip`.
  final String placement;

  /// The "Active · Visible in app" toggle. Distinct from [lifecycleStatus],
  /// which also folds in the date window.
  final bool isActive;

  /// Lower sorts first.
  final int displayOrder;

  /// Computed server-side: `active` · `scheduled` · `inactive` · `expired`.
  final String lifecycleStatus;

  final int impressionCount;
  final int tapCount;

  /// CDN URL of the artwork, or null when the banner has no image.
  /// Read-only — set by uploading an `image` file, never assigned directly.
  final String? imageUrl;

  /// Free-text client route opened on tap — one half of the form's "Links to".
  final String? deepLink;

  /// Linked coupon id — the other half of "Links to".
  final int? couponId;

  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Status label and badge tone.
  (String label, BadgeTone tone) get statusDisplay => switch (lifecycleStatus) {
        'active' => ('Active', BadgeTone.green),
        'scheduled' => ('Scheduled', BadgeTone.blue),
        'expired' => ('Expired', BadgeTone.grey),
        _ => ('Inactive', BadgeTone.grey),
      };

  /// Human label for the placement chip on the card.
  String get placementLabel =>
      placement == 'home_strip' ? 'Home — Strip' : 'Home — Hero';

  /// What the card's footer shows for "Links to". The API splits this across
  /// two fields, so prefer whichever is set.
  String get linkLabel {
    final link = deepLink;
    if (link != null && link.trim().isNotEmpty) return link.trim();
    final coupon = couponId;
    if (coupon != null) return 'Coupon #$coupon';
    return 'No link';
  }

  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;
}
