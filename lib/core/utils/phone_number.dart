import 'package:flutter/services.dart';

/// Indian mobile numbers for the worker sign-in field.
///
/// The country code is not something the admin types — it is fixed at `+91` and
/// shown as a static prefix on the field, so the input holds the ten national
/// digits only. [e164] is what goes to the API; [national] unpacks a stored
/// value back into those ten digits for editing.
class PhoneNumber {
  const PhoneNumber._();

  /// The only country code this console hires into.
  static const String dialCode = '+91';

  /// Digits in an Indian national mobile number.
  static const int nationalLength = 10;

  /// The ten national digits of [raw], tolerating anything already stored:
  /// `+91 97468 63592`, `9197468...`, `097468...` all reduce to `9746863592`.
  /// Returns the digits as-is when they match no known prefix shape, so a
  /// legacy or malformed value is shown for correction rather than mangled.
  static String national(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == nationalLength + 2 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == nationalLength + 1 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// True when [raw] holds a complete national number. Indian mobiles start
  /// 6–9, so a ten-digit value outside that range is a typo, not a number.
  static bool isValid(String raw) {
    final digits = national(raw);
    return digits.length == nationalLength &&
        RegExp(r'^[6-9]').hasMatch(digits);
  }

  /// The API form: `+919746863592`. Empty when [raw] is not a complete number,
  /// so a half-typed value is never sent.
  static String e164(String raw) {
    if (!isValid(raw)) return '';
    return '$dialCode${national(raw)}';
  }

  /// Field-level message, or null when the value is empty or complete.
  static String? errorFor(String raw) {
    final digits = national(raw);
    if (digits.isEmpty) return null;
    if (digits.length < nationalLength) return 'Enter all 10 digits.';
    if (digits.length > nationalLength) return 'Indian numbers are 10 digits.';
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile numbers start with 6, 7, 8 or 9.';
    }
    return null;
  }
}

/// Keeps the phone field to ten digits — the `+91` lives outside the field, so
/// a pasted `+91 97468 63592` is reduced rather than rejected.
class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PhoneNumber.national(newValue.text);
    final clamped = digits.length > PhoneNumber.nationalLength
        ? digits.substring(0, PhoneNumber.nationalLength)
        : digits;
    return TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
  }
}
