/// Result of the driver marking the outstanding balance as collected in cash.
///
/// The collect-cash endpoint answers with a settlement-only slice of the job
/// (id, reference, status and the payment flags) rather than the full job
/// payload, so this is deliberately narrower than `JobDetail` — the caller
/// merges these fields onto the job it already holds.
class CashCollection {
  final String id;
  final String reference;
  final String status;
  final bool isPaid;
  final String balanceDue;
  final bool balancePaid;
  final String? balancePaidAt;

  const CashCollection({
    required this.id,
    required this.reference,
    required this.status,
    required this.isPaid,
    required this.balanceDue,
    required this.balancePaid,
    this.balancePaidAt,
  });
}
