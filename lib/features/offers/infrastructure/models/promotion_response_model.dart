import '../../domain/entities/offer_banner.dart';

/// One banner in the `PromotionSerializer` read shape.
class PromotionModel {
  const PromotionModel({
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
    this.coupon,
    this.startsAt,
    this.endsAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: '${json['id']}',
      title: _str(json['title']),
      subtitle: _str(json['subtitle']),
      badgeText: _str(json['badge_text']),
      placement: _str(json['placement'], fallback: 'home_hero'),
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: _int(json['display_order']),
      lifecycleStatus: _str(json['lifecycle_status'], fallback: 'inactive'),
      impressionCount: _int(json['impression_count']),
      tapCount: _int(json['tap_count']),
      imageUrl: _nullableStr(json['image_url']),
      deepLink: _nullableStr(json['deep_link']),
      coupon: json['coupon'] is int
          ? json['coupon'] as int
          : int.tryParse('${json['coupon']}'),
      startsAt: _date(json['starts_at']),
      endsAt: _date(json['ends_at']),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String placement;
  final bool isActive;
  final int displayOrder;
  final String lifecycleStatus;
  final int impressionCount;
  final int tapCount;
  final String? imageUrl;
  final String? deepLink;
  final int? coupon;
  final DateTime? startsAt;
  final DateTime? endsAt;

  OfferBanner toEntity() => OfferBanner(
        id: id,
        title: title,
        subtitle: subtitle,
        badgeText: badgeText,
        placement: placement,
        isActive: isActive,
        displayOrder: displayOrder,
        lifecycleStatus: lifecycleStatus,
        impressionCount: impressionCount,
        tapCount: tapCount,
        imageUrl: imageUrl,
        deepLink: deepLink,
        couponId: coupon,
        // The API sends UTC; the forms and cards all speak local time.
        startsAt: startsAt?.toLocal(),
        endsAt: endsAt?.toLocal(),
      );

  static String _str(Object? v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = '$v'.trim();
    return s.isEmpty || s == 'null' ? fallback : s;
  }

  static String? _nullableStr(Object? v) {
    final s = _str(v);
    return s.isEmpty ? null : s;
  }

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse('$v');
  }
}

/// The DRF paginated envelope for `GET /api/shop/v1/promotions/`.
class PromotionListResponse {
  const PromotionListResponse({required this.results, required this.count});

  factory PromotionListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    return PromotionListResponse(
      results: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(PromotionModel.fromJson)
              .toList()
          : const [],
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse('${json['count']}') ?? 0,
    );
  }

  final List<PromotionModel> results;
  final int count;
}
