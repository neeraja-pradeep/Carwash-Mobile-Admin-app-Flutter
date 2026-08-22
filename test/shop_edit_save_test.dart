import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/shops/infrastructure/models/shop_detail_response_model.dart';

/// Editing a shop used to be a stub: the screen toasted "Shop details saved"
/// and popped without calling anything, so every change was lost. It now
/// PATCHes — and because the form has no inputs for some stored columns, the
/// body must carry only what was actually edited.
void main() {
  group('ShopUpdateRequest', () {
    test('sends the edited fields under their API names', () {
      final body = const ShopUpdateRequest(
        name: 'Sparkle Motors',
        address: 'MG Road',
        pincode: '682001',
        phone: '9876543210',
        ownerName: 'Anand',
        ownerPhone: '9876543211',
        dailyBookingCap: 20,
        commissionType: 'percent_floor',
        commissionPercentage: '15',
        commissionFloor: '30',
        bankAccountName: 'Sparkle',
        bankAccountNumber: '00011122',
        bankIfsc: 'HDFC0001234',
        upiId: 'sparkle@upi',
        gstin: '32ABCFS1234K1Z5',
      ).toJson();

      expect(body['name'], 'Sparkle Motors');
      expect(body['owner_name'], 'Anand');
      expect(body['owner_phone'], '9876543211');
      expect(body['daily_booking_cap'], 20);
      expect(body['commission_type'], 'percent_floor');
      expect(body['commission_percentage'], '15');
      expect(body['commission_floor'], '30');
      expect(body['bank_account_number'], '00011122');
      expect(body['upi_id'], 'sparkle@upi');
      expect(body['gstin'], '32ABCFS1234K1Z5');
    });

    test('carries the live status the activation toggle writes', () {
      // The "Shop active" toggle used to move a local flag only — the request
      // had no status field at all, so activation never left the device.
      expect(
        const ShopUpdateRequest(status: 'active').toJson(),
        {'status': 'active'},
      );
      expect(
        const ShopUpdateRequest(status: 'inactive').toJson(),
        {'status': 'inactive'},
      );
    });

    test('omits every field that was not supplied', () {
      // The critical property: city and state have no inputs on the form, so
      // they must be absent from the body rather than sent blank — a PATCH
      // carrying 'city': '' would erase what the shop already has.
      final body = const ShopUpdateRequest(name: 'Sparkle Motors').toJson();

      expect(body, {'name': 'Sparkle Motors'});
      expect(body.containsKey('status'), isFalse);
      expect(body.containsKey('city'), isFalse);
      expect(body.containsKey('state'), isFalse);
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('gstin'), isFalse);
    });

    test('carries the re-picked location so the pin actually moves', () {
      final body = const ShopUpdateRequest(
        latitude: 9.4981,
        longitude: 76.3385,
        city: 'Kochi',
        state: 'Kerala',
      ).toJson();

      expect(body['latitude'], 9.4981);
      expect(body['longitude'], 76.3385);
      expect(body['city'], 'Kochi');
      expect(body['state'], 'Kerala');
    });

    test('an empty edit sends an empty body, not a wipe', () {
      expect(const ShopUpdateRequest().toJson(), isEmpty);
    });

    test('a vehicle-type list survives as a list', () {
      final body = const ShopUpdateRequest(
        supportedVehicleTypes: ['hatchback', 'suv'],
      ).toJson();

      expect(body['supported_vehicle_types'], ['hatchback', 'suv']);
    });
  });

  group('ShopCreateRequest', () {
    test('includes the GSTIN the form collects', () {
      // The form has had a GSTIN input all along; create used to hardcode null.
      final body = ShopCreateRequest(
        name: 'Sparkle Motors',
        address: 'MG Road',
        pincode: '682001',
        city: 'Kochi',
        state: 'Kerala',
        phone: '9876543210',
        ownerName: 'Anand',
        ownerPhone: '9876543211',
        gstin: '32ABCFS1234K1Z5',
      ).toJson();

      expect(body['gstin'], '32ABCFS1234K1Z5');
      expect(body['city'], 'Kochi');
      expect(body['state'], 'Kerala');
    });

    test('leaves GSTIN out when the admin did not enter one', () {
      final body = ShopCreateRequest(
        name: 'Sparkle Motors',
        address: 'MG Road',
        pincode: '682001',
        city: '',
        state: '',
        phone: '9876543210',
        ownerName: 'Anand',
        ownerPhone: '9876543211',
      ).toJson();

      expect(body.containsKey('gstin'), isFalse);
    });
  });
}
