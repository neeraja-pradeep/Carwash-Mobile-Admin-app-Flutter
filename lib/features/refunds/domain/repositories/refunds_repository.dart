import '../entities/refund.dart';

/// Abstract contract for reading refunds. No implementation here.
abstract class RefundsRepository {
  /// All refunds (paginated) with optional filters, search, and sort.
  Future<List<Refund>> fetchRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
  });

  /// Get a single refund by ID.
  Future<Refund?> getRefundById(String id);
}
