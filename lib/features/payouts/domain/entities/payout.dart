import 'package:new_flutter_project/core/status/badge_tone.dart';

/// A single booking line within a payout.
class PayoutBooking {
  const PayoutBooking({
    required this.date,
    required this.id,
    required this.customer,
    required this.gross,
    required this.commission,
    required this.refund,
    required this.excluded,
  });

  final String date;
  final String id;
  final String customer;
  final int gross;
  final int commission;
  final int refund;
  final bool excluded;

  PayoutBooking copyWith({bool? excluded}) => PayoutBooking(
        date: date,
        id: id,
        customer: customer,
        gross: gross,
        commission: commission,
        refund: refund,
        excluded: excluded ?? this.excluded,
      );
}

/// An adjustment line (positive = bonus, negative = deduction).
class PayoutAdjustment {
  const PayoutAdjustment({
    required this.amount,
    required this.reason,
    required this.at,
  });

  final int amount;
  final String reason;
  final String at;
}

/// Computed totals derived from non-excluded bookings + adjustments.
class PayoutCalc {
  const PayoutCalc({
    required this.gross,
    required this.commission,
    required this.refunds,
    required this.adj,
    required this.net,
  });

  final int gross;
  final int commission;
  final int refunds;
  final int adj;
  final int net;
}

/// A shop payout record.
class Payout {
  const Payout({
    required this.id,
    required this.shopId,
    required this.period,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.utr,
    required this.proof,
    required this.adjustments,
    required this.bookings,
  });

  final String id;
  final String shopId;
  final String period;

  /// `pending` | `paid`
  final String status;
  final String createdAt;
  final String? paidAt;
  final String utr;
  final bool proof;
  final List<PayoutAdjustment> adjustments;
  final List<PayoutBooking> bookings;

  BadgeTone get tone =>
      status == 'paid' ? BadgeTone.green : BadgeTone.amber;

  String get statusLabel => status == 'paid' ? 'Paid' : 'Pending';

  /// Computes totals from non-excluded bookings + adjustments.
  PayoutCalc get calc {
    final inc = bookings.where((b) => !b.excluded).toList();
    final gross = inc.fold<int>(0, (s, b) => s + b.gross);
    final commission = inc.fold<int>(0, (s, b) => s + b.commission);
    final refunds = inc.fold<int>(0, (s, b) => s + b.refund);
    final adj = adjustments.fold<int>(0, (s, a) => s + a.amount);
    return PayoutCalc(
      gross: gross,
      commission: commission,
      refunds: refunds,
      adj: adj,
      net: gross - commission - refunds + adj,
    );
  }
}
