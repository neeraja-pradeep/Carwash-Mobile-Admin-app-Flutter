/// Hive box names. Feature-based, never generic. `static const String`,
/// camelCase identifier, snake_case value (per the project lint rules).
class HiveBoxes {
  const HiveBoxes._();

  /// 3-layer HTTP cache box (L2), wired in the API-integration phase.
  static const String cache = 'cache';
  static const String auth = 'auth';
  static const String settings = 'settings';
}
