import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/shops/infrastructure/models/shop_list_response_model.dart';

/// A trimmed row of GET /api/shop/v1/shops/ as the backend returns it: the list
/// endpoint sends commission and services as ready-made summaries, not as the
/// nested objects the detail response carries.
Map<String, dynamic> _row({Map<String, dynamic> overrides = const {}}) => {
      'id': 1,
      'name': 'Test Car Shop',
      'area': 'G8HQ+5PX, Vyasapuram, Alappuzha, Kerala',
      'city': '',
      'status': 'active',
      'rating': null,
      'rating_count': 0,
      'cover_image_url': 'car-wash.b-cdn.net/shops/cover/abc.webp',
      'is_open_now': true,
      'today_bookings': 0,
      'capacity': {'used': 0, 'total': 205},
      'commission_label': '20%',
      'services_count': 5,
      ...overrides,
    };

void main() {
  group('ShopListItemModel.toDomain', () {
    test('keeps the row\'s commission and services summaries', () {
      // Both were parsed but dropped on the way to the entity, so every card
      // read "₹0/booking · 0 services" however the shop was configured.
      final shop = ShopListItemModel.fromJson(_row()).toDomain();

      expect(shop.commissionText, '20%');
      expect(shop.activeServices, 5);
    });

    test('carries a flat-fee label through unchanged', () {
      final shop = ShopListItemModel.fromJson(
        _row(overrides: {'commission_label': '₹77/booking'}),
      ).toDomain();

      expect(shop.commissionText, '₹77/booking');
    });

    test('falls back to the computed label when the row has none', () {
      final shop = ShopListItemModel.fromJson(
        _row(overrides: {'commission_label': null, 'services_count': 0}),
      ).toDomain();

      expect(shop.commissionText, shop.commission.label);
      expect(shop.activeServices, 0);
    });

    test('still maps the rest of the row', () {
      final shop = ShopListItemModel.fromJson(_row()).toDomain();

      expect(shop.name, 'Test Car Shop');
      expect(shop.cap, 205);
      expect(shop.active, isTrue);
      expect(shop.photos.single.url,
          'https://car-wash.b-cdn.net/shops/cover/abc.webp');
    });
  });
}
