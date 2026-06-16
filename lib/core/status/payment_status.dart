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

/// Resolves a wire-key to a [PaymentStatus].
PaymentStatus paymentStatusFromKey(String key) {
  return PaymentStatus.values.firstWhere(
    (s) => s.name == key,
    orElse: () => PaymentStatus.pending,
  );
}
