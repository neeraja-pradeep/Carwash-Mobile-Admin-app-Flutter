import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A discount coupon.
class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.maxDiscount,
    required this.minOrder,
    required this.status,
    required this.scope,
    required this.usageLimit,
    required this.usedCount,
    required this.perUser,
    required this.validFrom,
    required this.validTo,
    required this.description,
    this.scopeShops = const [],
  });

  final String id;
  final String code;
  /// `percentage` | `flat`
  final String type;
  final num value;
  final num? maxDiscount;
  final num minOrder;
  /// `active` | `scheduled` | `paused` | `expired`
  final String status;
  final String scope;
  final int usageLimit;
  final int usedCount;
  final int perUser;
  final String validFrom;
  final String validTo;
  final String description;
  final List<String> scopeShops;

  /// Status label and badge tone.
  (String label, BadgeTone tone) get statusDisplay => switch (status) {
        'active' => ('Active', BadgeTone.green),
        'scheduled' => ('Scheduled', BadgeTone.blue),
        'paused' => ('Paused', BadgeTone.amber),
        _ => ('Expired', BadgeTone.grey),
      };

  /// Usage fraction (0..1) — clamped.
  double get usageFraction =>
      usageLimit == 0 ? 0 : (usedCount / usageLimit).clamp(0.0, 1.0);

  /// Returns true if the coupon should be sorted to the bottom (expired/paused).
  bool get isTerminal => status == 'expired' || status == 'paused';
}
