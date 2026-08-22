import 'package:flutter/services.dart';

/// The licence expiry the form collects — month and year only, `MM-YYYY`.
///
/// The admin types digits; the hyphen is inserted for them once the month is
/// complete. Stored values arrive from the API as ISO `YYYY-MM-DD`, so
/// [fromStored] unpacks one back into the two fields the form edits.
class ExpiryDate {
  const ExpiryDate._();

  /// `MM` + `YYYY` — the digits a complete value holds.
  static const int digitCount = 6;

  /// Longest a canonical value gets: 6 digits + the hyphen.
  static const int maxLength = digitCount + 1;

  static final RegExp _canonical = RegExp(r'^(\d{2})-(\d{4})$');

  /// Earliest year an expiry may plausibly carry — anything below this is a
  /// half-typed year, not a date.
  static const int minYear = 1950;

  /// Every digit in [raw], capped at [digitCount].
  static String compact(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > digitCount
        ? digits.substring(0, digitCount)
        : digits;
  }

  /// Re-groups a value into `MM-YYYY`. The hyphen lands as soon as the month
  /// is complete — including on a two-digit value, so it is already waiting
  /// when the admin starts the year.
  static String format(String raw) {
    final v = compact(raw);
    if (v.length < 2) return v;
    return '${v.substring(0, 2)}-${v.substring(2)}';
  }

  /// A stored `YYYY-MM-DD` (or `YYYY-MM`) value as the form's `MM-YYYY`.
  /// Anything else is returned trimmed but untouched, so a legacy or malformed
  /// value is shown for correction rather than mangled.
  static String fromStored(String raw) {
    final v = raw.trim();
    final iso = RegExp(r'^(\d{4})-(\d{2})(?:-\d{2})?').firstMatch(v);
    if (iso != null) return '${iso.group(2)}-${iso.group(1)}';
    return v;
  }

  /// The API form — the 1st of the expiry month, `YYYY-MM-01`. Null when [raw]
  /// is empty; the raw value when it is not a complete `MM-YYYY`.
  static String? toStored(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final m = _canonical.firstMatch(format(v));
    if (m == null) return v;
    return '${m.group(2)}-${m.group(1)}-01';
  }

  /// True when [raw] is a complete, well-formed expiry.
  static bool isValid(String raw) =>
      compact(raw).length == digitCount && errorFor(raw) == null;

  /// A one-line reason [raw] is not a usable expiry, or null when it is fine.
  /// Blank input returns null — "required" is the form's business, not this
  /// validator's, and a half-typed value is not yet wrong.
  static String? errorFor(String raw, {int? currentYear}) {
    final v = compact(raw);
    if (v.isEmpty) return null;

    final month = int.tryParse(v.substring(0, v.length.clamp(0, 2)));
    if (month != null && v.length >= 2 && (month < 1 || month > 12)) {
      return 'Month must be between 01 and 12.';
    }

    if (v.length < digitCount) return null;

    final year = int.parse(v.substring(2));
    final maxYear = (currentYear ?? DateTime.now().year) + 50;
    if (year < minYear || year > maxYear) {
      return 'Year must be between $minYear and $maxYear.';
    }

    return null;
  }
}

/// Keeps an expiry field in `MM-YYYY` shape while typing: digits only, the
/// hyphen inserted after the month and removed again when it is backspaced
/// over, and no more than six digits.
class ExpiryDateInputFormatter extends TextInputFormatter {
  const ExpiryDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = ExpiryDate.compact(newValue.text);

    // Backspacing over the auto-inserted hyphen would otherwise be a no-op —
    // the digits are unchanged, so it would be re-inserted immediately. Drop
    // the digit in front of it instead, which is what the admin meant.
    final deleted = newValue.text.length < oldValue.text.length;
    if (deleted &&
        oldValue.text.length > 2 &&
        oldValue.text[2] == '-' &&
        !newValue.text.contains('-') &&
        digits.length == ExpiryDate.compact(oldValue.text).length) {
      // The hyphen always sits at index 2, so the digit in front of it is
      // the month's second — that is the one that goes.
      digits = digits.substring(0, 1) + digits.substring(2);
    }

    final formatted = ExpiryDate.format(digits);

    // Keep the caret at the end when appending (the common case); otherwise
    // clamp it into the reformatted string so it never lands out of range.
    final delta = formatted.length - newValue.text.length;
    final offset = (newValue.selection.baseOffset + delta)
        .clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
