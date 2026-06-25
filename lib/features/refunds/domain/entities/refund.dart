import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A single step in the refund lifecycle stepper.
class RefundStep {
  const RefundStep({
    required this.key,
    required this.label,
    required this.done,
    this.at,
  });

  /// `requested` | `approved` | `paid`
  final String key;
  final String label;
  final bool done;

  /// ISO datetime, or `null` if not yet reached.
  final String? at;
}

/// Payment proof captured at Mark-Paid.
class RefundPaymentProof {
  const RefundPaymentProof({
    this.reference,
    this.screenshotUrl,
    this.onFile = false,
    this.requiredBeforePaid = true,
  });

  final String? reference;
  final String? screenshotUrl;
  final bool onFile;
  final bool requiredBeforePaid;
}

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
    this.reference,
    this.bookingReference,
    this.bookingType,
    this.kind,
    this.rawStatus,
    this.reasonLabel,
    this.reasonSubtitle,
    this.percent,
    this.steps = const [],
    this.nextAction,
    this.paymentProof,
    this.createdByName,
  });

  final String id;
  final int amount;

  /// `requested` | `approved` | `paid` | `declined`
  final String status;

  /// The underlying booking id (numeric string).
  final String bookingId;
  final RefundCustomer customer;
  final String tier;

  /// Structured reason key (e.g. `service_quality_issue`).
  final String reason;
  final String notes;
  final String createdAt;
  final String? approvedAt;
  final String? paidAt;
  final String utr;
  final bool proof;

  /// The refund reference (e.g. `RF-20260620-009`); `null` for `request` items.
  final String? reference;

  /// Booking reference (`DT-…` carwash / `SR-…` DI).
  final String? bookingReference;

  /// `carwash` | `driver_inspection`.
  final String? bookingType;

  /// `refund` (real row) | `request` (synthesized awaiting decision).
  final String? kind;

  /// Underlying row status: `pending` / `processed` / `declined` / `failed`.
  final String? rawStatus;

  /// Human label for [reason].
  final String? reasonLabel;

  /// Longer human description / the customer's note.
  final String? reasonSubtitle;

  /// Tier percent, when set.
  final double? percent;

  /// The lifecycle stepper.
  final List<RefundStep> steps;

  /// Footer action: `approve` | `mark_paid` | `null` (terminal).
  final String? nextAction;

  final RefundPaymentProof? paymentProof;

  /// Admin who created the refund row.
  final String? createdByName;

  /// What the detail screen should resolve against the API — prefers the
  /// `RF-…` reference, falling back to the numeric id.
  String get detailKey => (reference != null && reference!.isNotEmpty)
      ? reference!
      : id;

  /// Display label for the booking row (reference preferred over numeric id).
  String get bookingLabel =>
      (bookingReference != null && bookingReference!.isNotEmpty)
          ? bookingReference!
          : bookingId;

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

  /// Reason to display — human label if present, else the raw key.
  String get reasonDisplay =>
      (reasonLabel != null && reasonLabel!.isNotEmpty) ? reasonLabel! : reason;
}

/// Inline customer sub-object on a refund.
class RefundCustomer {
  const RefundCustomer({required this.name, required this.phone});

  final String name;
  final String phone;
}
