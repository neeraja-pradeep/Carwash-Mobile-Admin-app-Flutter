/// Global, non-style application constants.
///
/// Anything that is not a colour/spacing token lives here: locale defaults,
/// demo credentials for the UI-only prototype, currency formatting, etc. These
/// are intentionally centralised so the API-integration phase can replace the
/// demo values without hunting across files.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Drivey';
  static const String appVersion = 'v0.1.0 (build 47)';

  // Locale / formatting defaults (IST, INR, English).
  static const String currencySymbol = '₹'; // ₹
  static const String locale = 'en_IN';

  // Demo credentials used by the UI-only prototype (replaced by real auth in
  // the API-integration phase).
  static const String demoAdminPassword = 'drivedeck';
  static const String demoOtp = '1234';

  // "Today" anchor used by the static sample data set.
  static const String sampleToday = '29 May 2026';

  /// Brief simulated load so list screens show their skeleton on cold start
  /// (matches the prototype). Replaced by real network latency in the API phase.
  static const Duration sampleLoadDelay = Duration(milliseconds: 450);
}
