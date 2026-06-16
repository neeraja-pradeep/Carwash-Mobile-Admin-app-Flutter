/// A shop holiday that can apply to several shops at once.
class Holiday {
  const Holiday({
    required this.id,
    required this.date,
    required this.label,
    required this.shopIds,
  });

  /// ISO date, e.g. `2026-06-07`.
  final String date;
  final String id;
  final String label;
  final List<String> shopIds;
}
