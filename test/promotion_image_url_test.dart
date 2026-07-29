import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/core/utils/media_url.dart';
import 'package:new_flutter_project/features/offers/infrastructure/models/promotion_response_model.dart';

/// A banner's artwork uploaded fine and the PATCH returned 200, but the picture
/// never appeared: the server sends freshly uploaded BunnyCDN files back as a
/// bare host + path with **no scheme**, and a URI with no scheme has no host, so
/// the image loader rejects it. Seeded rows carry a full `https://…` URL, which
/// is why some banners rendered and uploaded ones did not.
void main() {
  group('resolveMediaUrl', () {
    test('adds https to the bare CDN host the uploader returns', () {
      expect(
        resolveMediaUrl(
            'car-wash.b-cdn.net/promotions/f1f594e3b3224828943b5e1df4f1745b.webp'),
        'https://car-wash.b-cdn.net/promotions/f1f594e3b3224828943b5e1df4f1745b.webp',
      );
    });

    test('leaves an already-absolute URL alone', () {
      const url = 'https://images.unsplash.com/photo-123.jpg';
      expect(resolveMediaUrl(url), url);
      expect(resolveMediaUrl('http://example.com/a.png'),
          'http://example.com/a.png');
    });

    test('upgrades a protocol-relative URL to https', () {
      expect(resolveMediaUrl('//cdn.example.com/a.webp'),
          'https://cdn.example.com/a.webp');
    });

    test('treats null and empty as "no image"', () {
      expect(resolveMediaUrl(null), isNull);
      expect(resolveMediaUrl(''), isNull);
      expect(resolveMediaUrl('   '), isNull);
    });
  });

  group('PromotionModel', () {
    /// Verbatim from the PATCH response for banner 2.
    const json = {
      'id': 2,
      'title': 'FIRST WASH ₹120 OFF',
      'subtitle': 'First-time customers get ₹120 off',
      'badge_text': 'WELCOME',
      'image_url':
          'car-wash.b-cdn.net/promotions/f1f594e3b3224828943b5e1df4f1745b.webp',
      'deep_link': '/shops',
      'coupon': 1,
      'placement': 'home_hero',
      'starts_at': '2026-06-18T21:20:49.330165+05:30',
      'ends_at': '2026-07-02T21:20:49.330165+05:30',
      'is_active': true,
      'display_order': 2,
      'impression_count': 0,
      'tap_count': 0,
      'lifecycle_status': 'expired',
    };

    test('normalises the uploaded image URL so the card can load it', () {
      final banner = PromotionModel.fromJson(json).toEntity();

      expect(banner.imageUrl, startsWith('https://'));
      expect(banner.hasImage, isTrue);
      expect(Uri.parse(banner.imageUrl!).host, 'car-wash.b-cdn.net');
    });

    test('maps the rest of the payload', () {
      final banner = PromotionModel.fromJson(json).toEntity();

      expect(banner.id, '2');
      expect(banner.badgeText, 'WELCOME');
      expect(banner.placement, 'home_hero');
      expect(banner.placementLabel, 'Home — Hero');
      expect(banner.displayOrder, 2);
      expect(banner.isActive, isTrue);
      // `is_active` is the toggle; the badge follows the computed lifecycle,
      // which is expired because the window closed on 02-Jul.
      expect(banner.lifecycleStatus, 'expired');
      expect(banner.statusDisplay.$1, 'Expired');
      // deep_link wins over the linked coupon for the footer label.
      expect(banner.linkLabel, '/shops');
    });

    test('a missing image is null rather than an unfetchable empty string', () {
      final banner =
          PromotionModel.fromJson({...json, 'image_url': null}).toEntity();

      expect(banner.imageUrl, isNull);
      expect(banner.hasImage, isFalse);
    });
  });
}
