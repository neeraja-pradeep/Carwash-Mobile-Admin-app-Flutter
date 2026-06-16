import '../entities/refund.dart';

/// Abstract contract for reading refunds. No implementation here.
abstract class RefundsRepository {
  /// All refunds, newest first.
  Future<List<Refund>> fetchRefunds();
}
