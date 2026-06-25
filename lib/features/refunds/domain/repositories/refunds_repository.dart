import '../entities/refund.dart';

/// Abstract contract for the refunds feature. No implementation here.
abstract class RefundsRepository {
  /// All refunds (paginated) with optional filters, search, and sort.
  ///
  /// [days] sets the `created_at` window (default 30; `0` disables).
  Future<List<Refund>> fetchRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
    int days = 30,
  });

  /// Refund detail by numeric id or `RF-…` reference (hits the detail endpoint).
  Future<Refund?> getRefundDetail(String idOrReference);

  /// Approve a customer refund request. Returns the updated refund.
  Future<Refund> approve({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  });

  /// Mark an approved refund paid. [refundRef] is the id or `RF-…` reference.
  Future<Refund> markPaid({
    required String refundRef,
    required String paymentProofReference,
    String? screenshotPath,
    bool manual = false,
  });

  /// Standalone create-by-reference (issues directly to Paid).
  Future<Refund> createStandalone({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
    bool manual = false,
    String? paymentKind,
  });

  /// Decline a refund request (terminal off-ramp).
  Future<Refund> decline({
    required String bookingReference,
    String? reason,
    String? comment,
  });
}
