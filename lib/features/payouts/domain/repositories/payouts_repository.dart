import '../entities/payout.dart';

/// Abstract contract for reading payouts.
abstract class PayoutsRepository {
  /// All payouts, newest first.
  Future<List<Payout>> fetchPayouts();
}
