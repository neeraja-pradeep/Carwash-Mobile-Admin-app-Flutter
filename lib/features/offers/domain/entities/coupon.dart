import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A discount coupon — aligned to the admin Coupons API shape.
///
/// The API exposes the coupon **code** as `name`, the discount as
/// `discount_type` + `discount_percentage`/`flat_amount`, and a computed
/// `lifecycle_status` badge. Legacy UI-facing getters ([code], [type],
/// [value], [status], [scope], [usageLimit], [usedCount], [perUser],
/// [validFrom], [validTo]) are kept as compatibility accessors so existing
/// widgets keep working.
class Coupon {
  const Coupon({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    this.discountPercentage,
    this.flatAmount,
    this.maxDiscount,
    this.minOrder,
    this.discountLabel = '',
    required this.limit,
    this.perUserLimit,
    this.usage = 0,
    this.usageRemaining = 0,
    this.appliesToAllShops = true,
    this.shopIds = const [],
    this.startDate,
    this.endDate,
    this.statusActive = true,
    this.isActive = false,
    this.lifecycleStatus = 'active',
  });

  /// Coupon id. Stored as a string for UI/navigation compatibility.
  final String id;

  /// The coupon **code** (unique). Maps to API `name`.
  final String name;
  final String description;

  /// `percentage` | `flat`
  final String discountType;

  /// Percent off (when [discountType] == `percentage`).
  final num? discountPercentage;

  /// Flat ₹ discount (when [discountType] == `flat`).
  final num? flatAmount;

  /// Optional rupee cap on a percentage discount.
  final num? maxDiscount;

  /// Minimum order amount required to apply.
  final num? minOrder;

  /// Badge text, e.g. `"50% OFF"` / `"₹100 OFF"`.
  final String discountLabel;

  /// Total redemption limit across all customers.
  final int limit;

  /// Max uses per customer; `null` = unlimited.
  final int? perUserLimit;

  /// Times redeemed so far.
  final int usage;

  /// `max(0, limit − usage)`.
  final int usageRemaining;

  /// `true` = global; `false` = restricted to [shopIds].
  final bool appliesToAllShops;

  /// The specific shops it applies to (empty when global).
  final List<int> shopIds;

  /// Validity window start.
  final DateTime? startDate;

  /// Validity window end.
  final DateTime? endDate;

  /// The stored "Active now" toggle. `false` = paused.
  final bool statusActive;

  /// Computed — `true` only when currently redeemable.
  final bool isActive;

  /// Computed badge — `active` · `scheduled` · `paused` · `expired`.
  final String lifecycleStatus;

  // ─── Compatibility getters (legacy UI names) ───────────────────────────────

  /// Legacy alias for the coupon code.
  String get code => name;

  /// Legacy alias for [discountType].
  String get type => discountType;

  /// Legacy numeric discount value (percent or flat amount).
  num get value =>
      discountType == 'percentage' ? (discountPercentage ?? 0) : (flatAmount ?? 0);

  /// Legacy alias for the computed lifecycle badge string.
  String get status => lifecycleStatus;

  /// Legacy scope label.
  String get scope => appliesToAllShops ? 'All shops' : 'Specific shops';

  /// Legacy alias for [limit].
  int get usageLimit => limit;

  /// Legacy alias for [usage].
  int get usedCount => usage;

  /// Legacy alias for [perUserLimit] (defaults to 1 when unlimited/null).
  int get perUser => perUserLimit ?? 1;

  /// Legacy ISO date strings (or empty when unset).
  String get validFrom => startDate?.toIso8601String() ?? '';
  String get validTo => endDate?.toIso8601String() ?? '';

  /// Legacy scope-shop names (ids as strings — names aren't returned by the API).
  List<String> get scopeShops => shopIds.map((e) => e.toString()).toList();

  /// Status label and badge tone.
  (String label, BadgeTone tone) get statusDisplay => switch (lifecycleStatus) {
        'active' => ('Active', BadgeTone.green),
        'scheduled' => ('Scheduled', BadgeTone.blue),
        'paused' => ('Paused', BadgeTone.amber),
        _ => ('Expired', BadgeTone.grey),
      };

  /// Usage fraction (0..1) — clamped.
  double get usageFraction =>
      limit == 0 ? 0 : (usage / limit).clamp(0.0, 1.0);

  /// Returns true if the coupon should be sorted to the bottom (expired/paused).
  bool get isTerminal =>
      lifecycleStatus == 'expired' || lifecycleStatus == 'paused';
}
