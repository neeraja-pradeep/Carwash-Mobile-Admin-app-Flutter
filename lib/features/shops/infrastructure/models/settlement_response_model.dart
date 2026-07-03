/// Settlement API response models
library;

class SettlementPendingResponse {
  final int shopId;
  final int count;
  final String netPayable;
  final String pendingTotal;
  final String? lastSettled;
  final String lifetimePaid;
  final List<PendingSettlementItem> items;

  SettlementPendingResponse({
    required this.shopId,
    required this.count,
    required this.netPayable,
    required this.pendingTotal,
    this.lastSettled,
    required this.lifetimePaid,
    required this.items,
  });

  factory SettlementPendingResponse.fromJson(Map<String, dynamic> json) {
    return SettlementPendingResponse(
      shopId: json['shop_id'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
      netPayable: json['net_payable'] as String? ?? '0.00',
      pendingTotal: json['pending_total'] as String? ?? '0.00',
      lastSettled: json['last_settled'] as String?,
      lifetimePaid: json['lifetime_paid'] as String? ?? '0.00',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => PendingSettlementItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PendingSettlementItem {
  final int bookingId;
  final String reference;
  final String appointmentDate;
  final String gross;
  final String commission;
  final String net;

  PendingSettlementItem({
    required this.bookingId,
    required this.reference,
    required this.appointmentDate,
    required this.gross,
    required this.commission,
    required this.net,
  });

  factory PendingSettlementItem.fromJson(Map<String, dynamic> json) {
    return PendingSettlementItem(
      bookingId: json['booking_id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      appointmentDate: json['appointment_date'] as String? ?? '',
      gross: json['gross'] as String? ?? '0.00',
      commission: json['commission'] as String? ?? '0.00',
      net: json['net'] as String? ?? '0.00',
    );
  }
}

class PayoutResponse {
  final int id;
  final int shop;
  final String grossAmount;
  final String commissionAmount;
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

  PayoutResponse({
    required this.id,
    required this.shop,
    required this.grossAmount,
    required this.commissionAmount,
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

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      id: json['id'] as int? ?? 0,
      shop: json['shop'] as int? ?? 0,
      grossAmount: json['gross_amount'] as String? ?? '0.00',
      commissionAmount: json['commission_amount'] as String? ?? '0.00',
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

class SettlementHistoryResponse {
  final int count;
  final List<PayoutResponse> results;

  SettlementHistoryResponse({
    required this.count,
    required this.results,
  });

  factory SettlementHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SettlementHistoryResponse(
      count: json['count'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => PayoutResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SettlementOverviewResponse {
  final int count;
  final List<SettlementOverviewItem> items;

  SettlementOverviewResponse({
    required this.count,
    required this.items,
  });

  factory SettlementOverviewResponse.fromJson(Map<String, dynamic> json) {
    return SettlementOverviewResponse(
      count: json['count'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => SettlementOverviewItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SettlementOverviewItem {
  final int shopId;
  final String name;
  final String pendingTotal;
  final int bookingCount;
  final SettlementPeriod? period;
  final SettlementLastPaid? lastPaid;

  SettlementOverviewItem({
    required this.shopId,
    required this.name,
    required this.pendingTotal,
    required this.bookingCount,
    this.period,
    this.lastPaid,
  });

  factory SettlementOverviewItem.fromJson(Map<String, dynamic> json) {
    return SettlementOverviewItem(
      shopId: json['shop_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      pendingTotal: json['pending_total'] as String? ?? '0.00',
      bookingCount: json['booking_count'] as int? ?? 0,
      period: json['period'] != null
          ? SettlementPeriod.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      lastPaid: json['last_paid'] != null
          ? SettlementLastPaid.fromJson(json['last_paid'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SettlementPeriod {
  final String start;
  final String end;

  SettlementPeriod({required this.start, required this.end});

  factory SettlementPeriod.fromJson(Map<String, dynamic> json) {
    return SettlementPeriod(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
    );
  }
}

class SettlementLastPaid {
  final String date;
  final String amount;

  SettlementLastPaid({required this.date, required this.amount});

  factory SettlementLastPaid.fromJson(Map<String, dynamic> json) {
    return SettlementLastPaid(
      date: json['date'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
    );
  }
}

/// Create payout request
class CreatePayoutRequest {
  final String? utr;
  final String? notes;

  CreatePayoutRequest({this.utr, this.notes});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (utr != null) json['utr'] = utr;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}
