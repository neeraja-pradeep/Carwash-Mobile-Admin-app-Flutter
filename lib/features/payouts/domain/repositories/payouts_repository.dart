/// Paginated payouts response (API response - different from old Payout entity)
class PayoutsPage {
  final List<PayoutLogItem> items;
  final int total;
  final bool hasNextPage;
  final int? nextPageNumber;

  PayoutsPage({
    required this.items,
    required this.total,
    required this.hasNextPage,
    this.nextPageNumber,
  });
}

/// Abstract contract for payout data access (API exclusive, no mock data)
abstract class PayoutsRepository {
  /// Get payout log with optional search, filters, and sort (last 90 days by default)
  ///
  /// Query params:
  /// - search: Shop name, UTR, or PO reference
  /// - status: "pending" / "paid" (comma-separated)
  /// - shop: Shop ID(s) (comma-separated)
  /// - sort: "recent" (default) / "net_desc" / "net_asc" / "shop"
  /// - days: Window size (default 90)
  /// - page / pageSize: Pagination
  Future<PayoutsPage> fetchPayoutLog({
    String? search,
    String? status,
    String? shop,
    String? sort,
    int? days,
    int page = 1,
    int pageSize = 10,
  });
}

/// Domain entity for a single payout log item (API response)
class PayoutLogItem {
  final int id;
  final String reference;
  final int shop;
  final String shopName;
  final double grossAmount;
  final double commissionAmount;
  final double refundsTotal;
  final double otherAdjustments;
  final double? netOverride;
  final double totalAmount;
  final int bookingCount;
  final String status;
  final String? utr;
  final String? notes;
  final String periodStart;
  final String periodEnd;
  final int createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<PayoutItemData> items;

  PayoutLogItem({
    required this.id,
    required this.reference,
    required this.shop,
    required this.shopName,
    required this.grossAmount,
    required this.commissionAmount,
    required this.refundsTotal,
    required this.otherAdjustments,
    this.netOverride,
    required this.totalAmount,
    required this.bookingCount,
    required this.status,
    this.utr,
    this.notes,
    required this.periodStart,
    required this.periodEnd,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.items,
  });
}

/// Per-booking line item in a payout
class PayoutItemData {
  final int id;
  final int booking;
  final String reference;
  final String appointmentDate;
  final double gross;
  final double commission;
  final double net;

  PayoutItemData({
    required this.id,
    required this.booking,
    required this.reference,
    required this.appointmentDate,
    required this.gross,
    required this.commission,
    required this.net,
  });
}
