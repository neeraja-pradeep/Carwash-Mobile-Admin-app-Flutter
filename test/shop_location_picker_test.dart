import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:new_flutter_project/core/location/geo_place.dart';
import 'package:new_flutter_project/core/location/geocoding_service.dart';
import 'package:new_flutter_project/features/shops/infrastructure/models/shop_detail_response_model.dart';

/// The Add/Edit Shop address field is now a map picker: the admin drops a pin,
/// the exact coordinates go to the backend, and the point's postal code is
/// fetched and written into the Pincode field.
///
/// These cover the two halves that don't need a live map: resolving a point to
/// an address + pincode, and getting the coordinates onto the wire.
void main() {
  /// Nominatim's reverse/search record for a point in Alappuzha.
  Map<String, dynamic> nominatimRecord({
    String lat = '9.4981',
    String lon = '76.3388',
    String postcode = '688011',
  }) =>
      {
        'lat': lat,
        'lon': lon,
        'display_name':
            'Mullackal, Alappuzha, Alappuzha district, Kerala, $postcode, India',
        'address': {
          'suburb': 'Mullackal',
          'city': 'Alappuzha',
          'state_district': 'Alappuzha district',
          'state': 'Kerala',
          'postcode': postcode,
          'country': 'India',
          'country_code': 'in',
        },
      };

  GeocodingService serviceReturning(
    Object body, {
    int status = 200,
    void Function(http.Request)? onRequest,
  }) {
    return GeocodingService(
      client: MockClient((request) async {
        onRequest?.call(request);
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  group('reverse geocoding a picked point', () {
    // The platform geocoder has no implementation under flutter_test, so these
    // exercise the Nominatim fallback — the same path a device without Play
    // services takes.

    test('pulls the pincode out so the form can auto-fill it', () async {
      final service = serviceReturning(nominatimRecord());
      addTearDown(service.dispose);

      final place = await service.reverse(9.4981, 76.3388);

      expect(place.pincode, '688011');
      expect(place.hasPincode, isTrue);
      expect(place.city, 'Alappuzha');
      expect(place.state, 'Kerala');
    });

    test('trims the country and pincode tail off the address line', () async {
      final service = serviceReturning(nominatimRecord());
      addTearDown(service.dispose);

      final place = await service.reverse(9.4981, 76.3388);

      // The Address field wants the street/locality part, not the postal tail
      // that the Pincode field already holds.
      expect(place.address,
          'Mullackal, Alappuzha, Alappuzha district, Kerala');
      expect(place.address, isNot(contains('India')));
      expect(place.address, isNot(contains('688011')));
    });

    test('keeps the picked coordinates verbatim', () async {
      final service = serviceReturning(nominatimRecord());
      addTearDown(service.dispose);

      // Nominatim snaps to the nearest mapped feature; the pin the admin
      // actually dropped is what the backend must store.
      final place = await service.reverse(9.570718196797932, 76.33691091203626);

      expect(place.latitude, 9.570718196797932);
      expect(place.longitude, 76.33691091203626);
      expect(place.coordsLabel, '9.570718, 76.336911');
    });

    test('still returns the coordinates when every geocoder fails', () async {
      final service = serviceReturning(const {}, status: 503);
      addTearDown(service.dispose);

      final place = await service.reverse(9.4981, 76.3388);

      // The admin can type the address by hand — but the pin must not be lost.
      expect(place.latitude, 9.4981);
      expect(place.longitude, 76.3388);
      expect(place.hasAddress, isFalse);
      expect(place.hasPincode, isFalse);
    });
  });

  group('search box', () {
    test('returns ranked places with their pincodes', () async {
      final service = serviceReturning([
        nominatimRecord(postcode: '688011'),
        nominatimRecord(lat: '9.51', lon: '76.34', postcode: '688013'),
      ]);
      addTearDown(service.dispose);

      final results = await service.search('Mullackal');

      expect(results, hasLength(2));
      expect(results.first.pincode, '688011');
      expect(results.last.latitude, 9.51);
      expect(results.last.pincode, '688013');
    });

    test('does not hit the network for fewer than 3 characters', () async {
      var calls = 0;
      final service = serviceReturning(
        const [],
        onRequest: (_) => calls++,
      );
      addTearDown(service.dispose);

      expect(await service.search('Mu'), isEmpty);
      expect(calls, 0);
    });

    test('degrades to no suggestions when the lookup fails', () async {
      final service = serviceReturning(const {'error': 'boom'}, status: 500);
      addTearDown(service.dispose);

      // A dead search must not block the admin — the map is still draggable.
      expect(await service.search('Mullackal'), isEmpty);
    });
  });

  group('GeoPlace', () {
    test('mergeMissing tops up only the fields left blank', () {
      const fromDevice = GeoPlace(
        latitude: 9.4981,
        longitude: 76.3388,
        address: 'Beach Rd, Thathampally',
      );
      const fromOsm = GeoPlace(
        latitude: 9.4981,
        longitude: 76.3388,
        address: 'Mullackal, Alappuzha',
        pincode: '688013',
      );

      final merged = fromDevice.mergeMissing(fromOsm);

      expect(merged.address, 'Beach Rd, Thathampally');
      expect(merged.pincode, '688013');
    });
  });

  group('create-shop payload', () {
    ShopCreateRequest request({double? latitude, double? longitude}) =>
        ShopCreateRequest(
          name: 'AquaShine Thathampally',
          address: 'Beach Rd, Thathampally, Alappuzha',
          pincode: '688013',
          city: '',
          state: '',
          phone: '+914772243390',
          ownerName: 'Suresh Kumar',
          ownerPhone: '+919946122087',
          latitude: latitude,
          longitude: longitude,
          commissionType: 'percentage',
        );

    test('sends the picked coordinates to the backend', () {
      final json = request(latitude: 9.4981, longitude: 76.3388).toJson();

      expect(json['latitude'], 9.4981);
      expect(json['longitude'], 76.3388);
      expect(json['pincode'], '688013');
    });

    test('omits both when the admin saved without picking a point', () {
      final json = request().toJson();

      // `location` is nullable server-side — sending nulls would be rejected
      // as invalid coordinates rather than treated as "unset".
      expect(json.containsKey('latitude'), isFalse);
      expect(json.containsKey('longitude'), isFalse);
    });
  });
}
