import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A customer refund record.
class Refund {
  const Refund({
    required this.id,
    required this.amount,
    required this.status,
    required this.bookingId,
    required this.customer,
    required this.tier,
    required this.reason,
    required this.notes,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
    required this.utr,
    required this.proof,
  });

  final String id;
  final int amount;

  /// `requested` | `approved` | `paid` | `declined`
  final String status;
  final String bookingId;
  final RefundCustomer customer;
  final String tier;
  final String reason;
  final String notes;
  final String createdAt;
  final String? approvedAt;
  final String? paidAt;
  final String utr;
  final bool proof;

  /// Maps status string to badge tone.
  BadgeTone get tone => switch (status) {
        'approved' => BadgeTone.blue,
        'paid' => BadgeTone.green,
        'declined' => BadgeTone.red,
        _ => BadgeTone.amber,
      };

  /// Human-readable status label.
  String get statusLabel => switch (status) {
        'approved' => 'Approved',
        'paid' => 'Paid',
        'declined' => 'Declined',
        _ => 'Requested',
      };
}

/// Inline customer sub-object on a refund.
class RefundCustomer {
  const RefundCustomer({required this.name, required this.phone});

  final String name;
  final String phone;
}
