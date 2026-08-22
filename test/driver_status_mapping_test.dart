import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/team_member.dart';
import 'package:new_flutter_project/features/drivers/infrastructure/models/driver_response_model.dart';

/// A minimal `/api/shop/v1/drivers/` row with the given status.
Map<String, dynamic> driverRow(String status) => {
      'id': 2,
      'user': {'id': 9, 'username': '9746863592', 'phone': '9746863592', 'email': 'n@d.test'},
      'name': 'Neeraja_DriverTest',
      'driver_status': status,
      'sub_role': 'hire',
      'role_label': 'Hire driver',
      'vehicle_classes': ['sedan'],
      'license_number': 'KL-07-2023-1234567',
      'license_expiry': '2030-01-01',
      'license_verified': true,
      'license_status': 'verified',
      'jobs_count': 0,
      'on_job': false,
      'documents': <dynamic>[],
    };

DriverStatus statusOf(String apiStatus) =>
    FieldDriverModel.fromJson(driverRow(apiStatus)).toEntity().status;

void main() {
  group('driver_status → DriverStatus', () {
    test('a worker who toggled themselves offline reads as offline', () {
      // The worker's own app writes `inactive` for offline. This used to fold
      // into `active`, so the admin roster showed them online indefinitely.
      expect(statusOf('inactive'), DriverStatus.offline);
      expect(DriverStatus.offline.label, 'Offline');
    });

    test('the pill reads Online / Offline, matching the toggle the worker sees', () {
      expect(statusOf('active').label, 'Online');
      expect(statusOf('inactive').label, 'Offline');
    });

    test('the admin-set states map through unchanged', () {
      expect(statusOf('active'), DriverStatus.online);
      expect(statusOf('invited'), DriverStatus.invited);
      expect(statusOf('suspended'), DriverStatus.suspended);
    });

    test('assigned reads as active — on a job is still online', () {
      expect(statusOf('assigned'), DriverStatus.online);
    });

    test('an unrecognised status falls back to offline, not online', () {
      // Falling back to online advertised a driver as available for dispatch
      // on nothing more than a mapping miss. Offline is the safe default: the
      // roster under-promises instead of dispatching to a driver who is gone.
      expect(statusOf('something_new'), DriverStatus.offline);
      expect(statusOf(''), DriverStatus.offline);
    });
  });

  group('TeamMember (the inspectors list on the Drivers screen)', () {
    TeamMember memberOf(String apiStatus) =>
        FieldDriverModel.fromJson(driverRow(apiStatus)).toTeamMember();

    test('a worker who went offline reads offline, not suspended', () {
      // This row used to collapse to `active: false` and render the red
      // "Suspended" pill — the same state as an admin-disabled account.
      expect(memberOf('inactive').status, DriverStatus.offline);
      expect(memberOf('inactive').status.label, 'Offline');
      expect(memberOf('inactive').active, isFalse);
    });

    test('a suspended worker still reads suspended', () {
      expect(memberOf('suspended').status, DriverStatus.suspended);
    });

    test('active is true only when the worker is on the books and online', () {
      expect(memberOf('active').active, isTrue);
      expect(memberOf('invited').active, isFalse);
    });
  });

  group('driverStatusParam', () {
    test('the offline filter queries the API status that backs it', () {
      expect(driverStatusParam(DriverStatus.offline), 'inactive');
      expect(driverStatusParam(DriverStatus.online), 'active');
      expect(driverStatusParam(null), isNull);
    });
  });
}
