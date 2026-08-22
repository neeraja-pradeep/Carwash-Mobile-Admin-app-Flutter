import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_flutter_project/core/utils/expiry_date.dart';

/// The hire/edit driver form collects the licence expiry as `MM-YYYY`: the
/// admin types digits and the hyphen is inserted for them.
void main() {
  group('ExpiryDate.format', () {
    test('adds the hyphen once the month is complete', () {
      expect(ExpiryDate.format(''), '');
      expect(ExpiryDate.format('0'), '0');
      expect(ExpiryDate.format('08'), '08-');
      expect(ExpiryDate.format('082'), '08-2');
      expect(ExpiryDate.format('082029'), '08-2029');
    });

    test('normalises a value that already carries separators', () {
      expect(ExpiryDate.format('08/2029'), '08-2029');
      expect(ExpiryDate.format('08-2029'), '08-2029');
    });

    test('stops at six digits', () {
      expect(ExpiryDate.format('0820299999'), '08-2029');
    });
  });

  group('ExpiryDate stored conversions', () {
    test('unpacks an ISO date for editing', () {
      expect(ExpiryDate.fromStored('2029-08-01'), '08-2029');
      expect(ExpiryDate.fromStored('2029-08'), '08-2029');
      expect(ExpiryDate.fromStored(''), '');
    });

    test('sends the 1st of the expiry month', () {
      expect(ExpiryDate.toStored('08-2029'), '2029-08-01');
      expect(ExpiryDate.toStored('082029'), '2029-08-01');
      expect(ExpiryDate.toStored(''), isNull);
    });

    test('passes a value it cannot read through untouched', () {
      expect(ExpiryDate.toStored('soon'), 'soon');
      expect(ExpiryDate.fromStored('soon'), 'soon');
    });
  });

  group('ExpiryDate.errorFor', () {
    test('accepts a well-formed expiry', () {
      expect(ExpiryDate.errorFor('08-2029', currentYear: 2026), isNull);
      expect(ExpiryDate.isValid('12-2030'), isTrue);
    });

    test('treats blank and half-typed values as not yet wrong', () {
      expect(ExpiryDate.errorFor(''), isNull);
      expect(ExpiryDate.errorFor('08-20'), isNull);
      expect(ExpiryDate.isValid('08-20'), isFalse);
    });

    test('rejects an impossible month', () {
      expect(ExpiryDate.errorFor('13-2029'), isNotNull);
      expect(ExpiryDate.errorFor('00-2029'), isNotNull);
    });

    test('rejects a year outside the plausible range', () {
      expect(ExpiryDate.errorFor('08-1849', currentYear: 2026), isNotNull);
      expect(ExpiryDate.errorFor('08-2999', currentYear: 2026), isNotNull);
    });
  });

  group('ExpiryDateInputFormatter', () {
    const formatter = ExpiryDateInputFormatter();

    TextEditingValue edit(String oldText, String text) =>
        formatter.formatEditUpdate(
          TextEditingValue(
            text: oldText,
            selection: TextSelection.collapsed(offset: oldText.length),
          ),
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );

    TextEditingValue type(String text) => edit('', text);

    test('inserts the hyphen as the admin types', () {
      expect(type('0').text, '0');
      expect(type('08').text, '08-');
      expect(type('082').text, '08-2');
      expect(type('082029').text, '08-2029');
    });

    test('drops characters that can never appear', () {
      expect(type('08 / 2029').text, '08-2029');
      expect(type('aug2029').text, '20-29');
    });

    test('stops at the full length', () {
      expect(type('08202912').text, '08-2029');
    });

    test('backspacing over the hyphen removes the digit in front of it', () {
      expect(edit('08-', '08').text, '0');
      expect(edit('08-2029', '082029').text, '02-029');
    });

    test('backspacing a year digit is left alone', () {
      expect(edit('08-2029', '08-202').text, '08-202');
    });

    test('keeps the caret inside the reformatted text', () {
      final result = type('082029');
      expect(result.selection.baseOffset, lessThanOrEqualTo(result.text.length));
      expect(result.selection.baseOffset, greaterThanOrEqualTo(0));
    });
  });
}
