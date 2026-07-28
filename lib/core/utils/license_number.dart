import 'package:flutter/services.dart';

/// Indian driving-licence numbers.
///
/// The licence number is `SS RR YYYY NNNNNNN` — a two-letter state code, the
/// two-digit RTO code, the four-digit year of issue and a seven-digit serial
/// (15 characters in all). RTAs print it with spaces, hyphens or nothing in
/// between, so input is normalised to the canonical hyphenated form
/// `KL-07-2011-0001234` and only the digits/letters are kept.
class LicenseNumber {
  const LicenseNumber._();

  /// Every state / union-territory RTO prefix, including the legacy spellings
  /// still printed on older licences (OR→OD, UA→UK, CT→CG, TS→TG).
  static const Set<String> stateCodes = {
    'AN', 'AP', 'AR', 'AS', 'BR', 'CG', 'CH', 'CT', 'DD', 'DL', 'DN', 'GA',
    'GJ', 'HP', 'HR', 'JH', 'JK', 'KA', 'KL', 'LA', 'LD', 'MH', 'ML', 'MN',
    'MP', 'MZ', 'NL', 'OD', 'OR', 'PB', 'PY', 'RJ', 'SK', 'TG', 'TN', 'TR',
    'TS', 'UA', 'UK', 'UP', 'WB',
  };

  /// Longest a canonical value gets: 15 characters + 3 hyphens.
  static const int maxLength = 18;

  static final RegExp _canonical =
      RegExp(r'^([A-Z]{2})-(\d{2})-(\d{4})-(\d{7})$');

  /// Strips separators and upper-cases, e.g. `kl 07 2011 0001234` → 15 chars.
  static String compact(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Re-groups a compact value into `KL-07-2011-0001234`, inserting hyphens
  /// only where the value has already reached them, so it can format partial
  /// input as the admin types.
  static String format(String raw) {
    final v = compact(raw);
    final parts = <String>[
      if (v.isNotEmpty) v.substring(0, v.length.clamp(0, 2)),
      if (v.length > 2) v.substring(2, v.length.clamp(0, 4)),
      if (v.length > 4) v.substring(4, v.length.clamp(0, 8)),
      if (v.length > 8) v.substring(8, v.length.clamp(0, 15)),
    ];
    return parts.join('-');
  }

  /// True when [raw] is a complete, well-formed licence number.
  static bool isValid(String raw) => errorFor(raw) == null;

  /// A one-line reason [raw] is not a usable licence number, or null when it
  /// is fine. Blank input returns null — "required" is the form's business,
  /// not this validator's.
  static String? errorFor(String raw, {int? currentYear}) {
    final v = compact(raw);
    if (v.isEmpty) return null;

    // Checked before formatting: [format] groups only the first 15 characters,
    // so a longer value would otherwise be trimmed into a valid-looking one.
    final match = v.length == 15 ? _canonical.firstMatch(format(v)) : null;
    if (match == null) {
      return 'Use the format KL-07-2011-0001234 '
          '(state, RTO, year, 7 digits).';
    }

    final state = match.group(1)!;
    if (!stateCodes.contains(state)) {
      return '$state is not a valid state code.';
    }

    final rto = int.parse(match.group(2)!);
    if (rto < 1) return 'RTO code must be 01 or higher.';

    final year = int.parse(match.group(3)!);
    final maxYear = currentYear ?? DateTime.now().year;
    if (year < 1950 || year > maxYear) {
      return 'Year of issue must be between 1950 and $maxYear.';
    }

    return null;
  }
}

/// Keeps a licence field in canonical shape while typing: upper-cases, drops
/// anything that is not a letter or digit, re-inserts the hyphens and stops at
/// 16 significant characters.
class LicenseNumberInputFormatter extends TextInputFormatter {
  const LicenseNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final compact = LicenseNumber.compact(newValue.text);
    final capped = compact.length > 15 ? compact.substring(0, 15) : compact;
    final formatted = LicenseNumber.format(capped);

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
