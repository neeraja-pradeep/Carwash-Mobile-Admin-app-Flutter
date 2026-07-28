import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/core/utils/license_number.dart';

/// The hire/edit driver form must accept only a standard Indian licence
/// number — `SS-RR-YYYY-NNNNNNN` — however the admin types it.
void main() {
  group('LicenseNumber.format', () {
    test('groups a compact number into the canonical form', () {
      expect(LicenseNumber.format('KL0720110001234'), 'KL-07-2011-0001234');
    });

    test('normalises spacing, hyphens and case', () {
      const expected = 'KL-07-2011-0001234';
      expect(LicenseNumber.format('kl 07 2011 0001234'), expected);
      expect(LicenseNumber.format('KL07 20110001234'), expected);
      expect(LicenseNumber.format('kl-07-2011-0001234'), expected);
      expect(LicenseNumber.format('KL/07/2011/0001234'), expected);
    });

    test('formats partial input without inventing separators', () {
      expect(LicenseNumber.format(''), '');
      expect(LicenseNumber.format('K'), 'K');
      expect(LicenseNumber.format('KL'), 'KL');
      expect(LicenseNumber.format('KL0'), 'KL-0');
      expect(LicenseNumber.format('KL07'), 'KL-07');
      expect(LicenseNumber.format('KL072011'), 'KL-07-2011');
    });
  });

  group('LicenseNumber.errorFor', () {
    test('accepts a well-formed number', () {
      expect(LicenseNumber.errorFor('KL-07-2011-0001234'), isNull);
      expect(LicenseNumber.errorFor('mh1420110062821'), isNull);
      expect(LicenseNumber.isValid('DL-01-1998-0123456'), isTrue);
    });

    test('treats blank as the form\'s problem, not a format error', () {
      expect(LicenseNumber.errorFor(''), isNull);
      expect(LicenseNumber.errorFor('   '), isNull);
    });

    test('rejects the shapes admins actually typed in', () {
      // Real values found on the server before this validation existed.
      expect(LicenseNumber.errorFor('kl39h12333'), isNotNull);
      expect(LicenseNumber.errorFor('KL39H1234'), isNotNull);
      expect(LicenseNumber.errorFor('Klt'), isNotNull);
    });

    test('rejects wrong lengths', () {
      expect(LicenseNumber.errorFor('KL-07-2011-000123'), isNotNull);
      expect(LicenseNumber.errorFor('KL-07-2011-00012345'), isNotNull);
    });

    test('rejects an unknown state code', () {
      final err = LicenseNumber.errorFor('XX-07-2011-0001234');
      expect(err, contains('state code'));
    });

    test('rejects an impossible year of issue', () {
      expect(
        LicenseNumber.errorFor('KL-07-1849-0001234'),
        contains('Year of issue'),
      );
      expect(
        LicenseNumber.errorFor('KL-07-2099-0001234', currentYear: 2026),
        contains('Year of issue'),
      );
      // The current year itself is fine.
      expect(
        LicenseNumber.errorFor('KL-07-2026-0001234', currentYear: 2026),
        isNull,
      );
    });

    test('rejects RTO code 00', () {
      expect(LicenseNumber.errorFor('KL-00-2011-0001234'), isNotNull);
    });
  });

  group('LicenseNumberInputFormatter', () {
    const formatter = LicenseNumberInputFormatter();

    TextEditingValue type(String text) => formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );

    test('upper-cases and re-groups as the admin types', () {
      expect(type('kl').text, 'KL');
      expect(type('kl07').text, 'KL-07');
      expect(type('kl072011').text, 'KL-07-2011');
      expect(type('kl0720110001234').text, 'KL-07-2011-0001234');
    });

    test('drops characters that can never appear', () {
      expect(type('KL#07*2011 0001234').text, 'KL-07-2011-0001234');
    });

    test('stops at the full length', () {
      expect(type('KL07201100012349999').text, 'KL-07-2011-0001234');
    });

    test('keeps the caret inside the reformatted text', () {
      final result = type('kl0720110001234');
      expect(result.selection.baseOffset, lessThanOrEqualTo(result.text.length));
      expect(result.selection.baseOffset, greaterThanOrEqualTo(0));
    });
  });
}
