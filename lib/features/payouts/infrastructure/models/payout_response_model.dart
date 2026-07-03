/// Payout Log API response models
library;

class PayoutsListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<PayoutData> results;

  PayoutsListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PayoutsListResponse.fromJson(Map<String, dynamic> json) {
    return PayoutsListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => PayoutData.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasNextPage => next != null && next!.isNotEmpty;
}

class PayoutData {
  final int id;
  final String reference;
  final int shop;
  final String shopName;
  final String grossAmount;
  final String commissionAmount;
  final String refundsTotal;
  final String otherAdjustments;
  final String? netOverride;
  final String totalAmount;
  final int bookingCount;
  final String status;
  final String? utr;
  final String? notes;
  final String periodStart;
  final String periodEnd;
  final int createdBy;
  final String createdByName;
  final String createdAt;
  final List<PayoutItem> items;

  PayoutData({
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

  factory PayoutData.fromJson(Map<String, dynamic> json) {
    return PayoutData(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      shop: json['shop'] as int? ?? 0,
      shopName: json['shop_name'] as String? ?? '',
      grossAmount: json['gross_amount'] as String? ?? '0.00',
      commissionAmount: json['commission_amount'] as String? ?? '0.00',
      refundsTotal: json['refunds_total'] as String? ?? '0.00',
      otherAdjustments: json['other_adjustments'] as String? ?? '0.00',
      netOverride: json['net_override'] as String?,
      totalAmount: json['total_amount'] as String? ?? '0.00',
      bookingCount: json['booking_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'paid',
      utr: json['utr'] as String?,
      notes: json['notes'] as String?,
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      createdBy: json['created_by'] as int? ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => PayoutItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PayoutItem {
  final int id;
  final int booking;
  final String reference;
  final String appointmentDate;
  final String gross;
  final String commission;
  final String net;

  PayoutItem({
    required this.id,
    required this.booking,
    required this.reference,
    required this.appointmentDate,
    required this.gross,
    required this.commission,
    required this.net,
  });

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      id: json['id'] as int? ?? 0,
      booking: json['booking'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      appointmentDate: json['appointment_date'] as String? ?? '',
      gross: json['gross'] as String? ?? '0.00',
      commission: json['commission'] as String? ?? '0.00',
      net: json['net'] as String? ?? '0.00',
    );
  }
}
