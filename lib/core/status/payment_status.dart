import 'badge_tone.dart';

/// Payment state shown on booking cards and detail screens.
enum PaymentStatus { paid, pending, refunded }

/// Display label and foreground colour for a [PaymentStatus].
extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.pending => 'Pending',
        PaymentStatus.refunded => 'Refunded',
      };

  BadgeTone get tone => switch (this) {
        PaymentStatus.paid => BadgeTone.green,
        PaymentStatus.pending => BadgeTone.amber,
        PaymentStatus.refunded => BadgeTone.red,
      };
}

/// The payment state to show for a booking, given every field that bears on it.
///
/// `payment_status` cannot be read on its own: this API returns `"pending"` for
/// every car-wash booking — settled, unsettled and refunded alike — so `is_paid`
/// is the field that actually separates paid from unpaid. The booking-level
/// `status` outranks both, since a refunded booking is neither paid nor pending.
///
/// The list card and the detail screen share this for the same reason they share
/// `resolveBookingStatus`: reading the fields their own way is how the list came
/// to show "Paid" on a booking the detail screen called "Pending".
PaymentStatus resolvePaymentStatus({
  String? bookingStatus,
  String? paymentStatus,
  bool? isPaid,
}) {
  if (bookingStatus == 'refunded') return PaymentStatus.refunded;

  final key = paymentStatus?.toLowerCase();
  if (key == 'refunded') return PaymentStatus.refunded;
  if (isPaid == true) return PaymentStatus.paid;

  return switch (key) {
    'paid' || 'success' || 'captured' => PaymentStatus.paid,
    _ => PaymentStatus.pending,
  };
}

/// Resolves a wire-key to a [PaymentStatus].
PaymentStatus paymentStatusFromKey(String key) {
  return PaymentStatus.values.firstWhere(
    (s) => s.name == key,
    orElse: () => PaymentStatus.pending,
  );
}
