import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/core/utils/phone_number.dart';

void main() {
  group('PhoneNumber.national', () {
    test('leaves a plain ten-digit number alone', () {
      expect(PhoneNumber.national('9746863592'), '9746863592');
    });

    test('unpacks a stored number that already carries the country code', () {
      // Editing an existing driver must show 10 digits, not +919746863592.
      expect(PhoneNumber.national('+919746863592'), '9746863592');
      expect(PhoneNumber.national('+91 97468 63592'), '9746863592');
      expect(PhoneNumber.national('919746863592'), '9746863592');
    });

    test('drops the trunk zero', () {
      expect(PhoneNumber.national('09746863592'), '9746863592');
    });

    test('keeps an unrecognised value visible for correction', () {
      // A legacy short number is shown as-is so the admin can fix it, rather
      // than being silently truncated into a plausible-looking number.
      expect(PhoneNumber.national('700'), '700');
    });
  });

  group('PhoneNumber.isValid', () {
    test('accepts a complete mobile number', () {
      for (final n in ['6000000000', '7746863592', '8746863592', '9746863592']) {
        expect(PhoneNumber.isValid(n), isTrue, reason: n);
      }
    });

    test('rejects an incomplete or over-long number', () {
      expect(PhoneNumber.isValid('974686359'), isFalse);
      expect(PhoneNumber.isValid(''), isFalse);
      expect(PhoneNumber.isValid('700'), isFalse);
    });

    test('rejects a ten-digit value that is not a mobile range', () {
      expect(PhoneNumber.isValid('1234567890'), isFalse);
      expect(PhoneNumber.isValid('5746863592'), isFalse);
    });
  });

  group('PhoneNumber.e164 — what reaches the API', () {
    test('prefixes +91 exactly once, whatever the input shape', () {
      expect(PhoneNumber.e164('9746863592'), '+919746863592');
      expect(PhoneNumber.e164('+919746863592'), '+919746863592');
      expect(PhoneNumber.e164('+91 97468 63592'), '+919746863592');
    });

    test('sends nothing for an incomplete number', () {
      // The CTA is disabled in this state; belt-and-braces so a partial number
      // can never be stored as someone's sign-in identity.
      expect(PhoneNumber.e164('97468'), '');
    });
  });

  group('PhoneNumber.errorFor', () {
    test('stays silent on an empty or complete field', () {
      expect(PhoneNumber.errorFor(''), isNull);
      expect(PhoneNumber.errorFor('9746863592'), isNull);
    });

    test('explains what is wrong while typing', () {
      expect(PhoneNumber.errorFor('97468'), 'Enter all 10 digits.');
      expect(PhoneNumber.errorFor('1234567890'),
          'Mobile numbers start with 6, 7, 8 or 9.');
    });
  });

  group('PhoneNumberInputFormatter', () {
    String format(String input) => const PhoneNumberInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: input))
        .text;

    test('strips a pasted country code rather than rejecting the paste', () {
      expect(format('+91 97468 63592'), '9746863592');
    });

    test('caps at ten digits', () {
      expect(format('97468635921234'), '9746863592');
    });

    test('drops letters and punctuation', () {
      expect(format('97a4b6-86 3592'), '9746863592');
    });
  });
}
