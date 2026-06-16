import 'package:intl/intl.dart';

import '../../app/config/constants.dart';

/// Shared value formatters (currency, counts, initials).
class Formatters {
  const Formatters._();

  static final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

  /// Formats an amount as Indian-grouped rupees, e.g. `₹8,450`.
  static String money(num value) =>
      '${AppConstants.currencySymbol}${_inr.format(value)}';

  /// Pluralises a noun against a count, e.g. `5 bookings`, `1 shop`.
  static String count(int n, String noun) =>
      '$n $noun${n == 1 ? '' : 's'}';

  /// Up-to-two-letter initials from a name, e.g. `Ramesh Kurup` → `RK`.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
