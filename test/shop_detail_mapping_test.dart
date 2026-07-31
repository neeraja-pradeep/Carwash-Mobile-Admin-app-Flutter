import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/shops/domain/entities/shop.dart';
import 'package:new_flutter_project/features/shops/infrastructure/models/shop_detail_response_model.dart';

/// A trimmed copy of GET /api/shop/v1/shops/1/ as the backend actually returns
/// it: scheme-less CDN paths, decimal commission, slug-plus-label vehicle types.
Map<String, dynamic> _detailJson({Map<String, dynamic> overrides = const {}}) => {
      'id': 1,
      'name': 'Test Car Shop',
      'status': 'active',
      'address': 'G8HQ+5PX, Vyasapuram, Alappuzha, Kerala',
      'city': '',
      'state': '',
      'pincode': '688006',
      'latitude': 9.497206995598628,
      'longitude': 76.34321476102275,
      'phone': '+916437216457',
      'cover_image_url': 'car-wash.b-cdn.net/shops/cover/abc.webp',
      'normal_image1_url': 'car-wash.b-cdn.net/shops/normal1/def.webp',
      'owner_name': 'Neeraja Owner',
      'owner_phone': '+919467375421',
      'capacity': {'used': 0, 'total': 20},
      'operating_hours': const <dynamic>[],
      'operational_config': {
        'daily_booking_cap': 20,
        'vehicle_types': [
          {'value': 'hatchback', 'label': 'Hatchback', 'supported': true},
          {'value': 'sedan', 'label': 'Sedan', 'supported': true},
          {'value': 'suv', 'label': 'SUV', 'supported': true},
          {'value': 'bike', 'label': 'Bike', 'supported': false},
        ],
        'is_active': true,
      },
      'settlement': {
        'commission': {
          'type': 'percentage',
          'percentage': 15.0,
          'amount': null,
          'floor': null,
          'label': '15%',
        },
        'bank': {
          'account_name': 'Bank Account',
          'account_number': '12134512134542131',
          'ifsc': '162728282',
          'upi_id': '152288289@bankaccount',
        },
      },
      ...overrides,
    };

Shop _toDomain({Map<String, dynamic> overrides = const {}}) =>
    ShopDetailResponseModel.fromJson(_detailJson(overrides: overrides))
        .toDomain();

void main() {
  group('shop detail → domain', () {
    test('gives BunnyCDN paths a scheme so the images can load', () {
      final shop = _toDomain();

      expect(shop.photos, [
        'https://car-wash.b-cdn.net/shops/cover/abc.webp',
        'https://car-wash.b-cdn.net/shops/normal1/def.webp',
      ]);
    });

    test('leaves an already absolute image URL alone', () {
      final shop = _toDomain(overrides: {
        'cover_image_url': 'https://cdn.example.com/a.webp',
        'normal_image1_url': null,
      });

      expect(shop.photos, ['https://cdn.example.com/a.webp']);
    });

    test('carries the coordinates the map link needs', () {
      final shop = _toDomain();

      expect(shop.latitude, closeTo(9.497206995598628, 1e-12));
      expect(shop.longitude, closeTo(76.34321476102275, 1e-12));
    });

    test('carries the pincode column the address does not contain', () {
      final shop = _toDomain();

      expect(shop.pincode, '688006');
      expect(RegExp(r'\b\d{6}\b').hasMatch(shop.address), isFalse);
    });

    test('keeps a decimal commission percentage instead of zeroing it', () {
      final shop = _toDomain();

      expect(shop.commission.mode, CommissionMode.percentage);
      expect(shop.commission.pct, 15);
      expect(shop.commission.label, '15%');
    });

    test('reads a percent_floor commission off decimal fields', () {
      final shop = _toDomain(overrides: {
        'settlement': {
          'commission': {
            'type': 'percent_floor',
            'percentage': 12.5,
            'floor': 30.0,
            'label': '12.5% · min ₹30',
          },
        },
      });

      expect(shop.commission.mode, CommissionMode.floor);
      expect(shop.commission.pct, 13); // 12.5 rounds to the nearest int
      expect(shop.commission.floor, 30);
    });

    test('labels supported vehicle types the way the chips are labelled', () {
      final shop = _toDomain();

      expect(shop.vehicleTypes, ['Hatchback', 'Sedan', 'SUV']);
    });

    test('maps the rest of the fields the edit form prefills from', () {
      final shop = _toDomain();

      expect(shop.name, 'Test Car Shop');
      expect(shop.ownerName, 'Neeraja Owner');
      expect(shop.ownerPhone, '+919467375421');
      expect(shop.shopPhone, '+916437216457');
      expect(shop.cap, 20);
      expect(shop.bank.accName, 'Bank Account');
      expect(shop.bank.accNo, '12134512134542131');
      expect(shop.bank.ifsc, '162728282');
      expect(shop.bank.upi, '152288289@bankaccount');
    });
  });
}
