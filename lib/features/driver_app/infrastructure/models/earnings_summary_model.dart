import '../../../drivers/domain/entities/driver_earnings.dart';

class EarningsDaySeries {
  const EarningsDaySeries({
    required this.day,
    required this.date,
    required this.amount,
  });

  final String day;
  final String date;
  final String amount;

  factory EarningsDaySeries.fromJson(Map<String, dynamic> json) {
    return EarningsDaySeries(
      day: json['day'] as String,
      date: json['date'] as String,
      amount: json['amount'] as String? ?? '0',
    );
  }

  int get amountInRupees => (double.tryParse(amount) ?? 0).toInt();
}

class EarningsBreakdownItem {
  const EarningsBreakdownItem({
    required this.count,
    required this.amount,
  });

  final int count;
  final String amount;

  factory EarningsBreakdownItem.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdownItem(
      count: json['count'] as int? ?? 0,
      amount: json['amount'] as String? ?? '0',
    );
  }

  int get amountInRupees => (double.tryParse(amount) ?? 0).toInt();
}

class EarningsWeek {
  const EarningsWeek({
    required this.start,
    required this.end,
    required this.total,
    required this.series,
  });

  final String start;
  final String end;
  final String total;
  final List<EarningsDaySeries> series;

  factory EarningsWeek.fromJson(Map<String, dynamic> json) {
    return EarningsWeek(
      start: json['start'] as String,
      end: json['end'] as String,
      total: json['total'] as String? ?? '0',
      series: (json['series'] as List<dynamic>?)
              ?.map((e) => EarningsDaySeries.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get totalInRupees => (double.tryParse(total) ?? 0).toInt();
}

class LastPaidInfo {
  const LastPaidInfo({
    required this.date,
    required this.amount,
  });

  final String date;
  final String amount;

  factory LastPaidInfo.fromJson(Map<String, dynamic> json) {
    return LastPaidInfo(
      date: json['date'] as String,
      amount: json['amount'] as String? ?? '0',
    );
  }

  int get amountInRupees => (double.tryParse(amount) ?? 0).toInt();
}

class EarningsSummaryModel {
  const EarningsSummaryModel({
    required this.week,
    required this.breakdown,
    required this.pendingPayout,
    required this.lastPaid,
  });

  final EarningsWeek week;
  final Map<String, EarningsBreakdownItem> breakdown;
  final String pendingPayout;
  final LastPaidInfo? lastPaid;

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <String, EarningsBreakdownItem>{};

    breakdownJson.forEach((key, value) {
      breakdown[key] = EarningsBreakdownItem.fromJson(value as Map<String, dynamic>);
    });

    return EarningsSummaryModel(
      week: EarningsWeek.fromJson(json['week'] as Map<String, dynamic>),
      breakdown: breakdown,
      pendingPayout: json['pending_payout'] as String? ?? '0',
      lastPaid: json['last_paid'] != null
          ? LastPaidInfo.fromJson(json['last_paid'] as Map<String, dynamic>)
          : null,
    );
  }

  int get pendingPayoutInRupees => (double.tryParse(pendingPayout) ?? 0).toInt();

  DriverEarnings toEntity() {
    final byDay = week.series.map((s) => (s.day, s.amountInRupees)).toList();

    final breakdownRows = <EarningsBreakdownRow>[];

    // Map breakdown items to display labels
    final labels = {
      'carwash': 'Carwash jobs',
      'driver_hire': 'Driver hire',
      'inspection': 'Inspection',
      'incentive': 'Incentives',
    };

    breakdown.forEach((key, item) {
      final label = labels[key] ?? key;
      if (item.count > 0 || item.amountInRupees > 0) {
        breakdownRows.add(
          EarningsBreakdownRow(
            label: label,
            count: item.count,
            amount: item.amountInRupees,
          ),
        );
      }
    });

    return DriverEarnings(
      todayTotal: 0, // Not provided by API, set to 0
      weekTotal: week.totalInRupees,
      pending: pendingPayoutInRupees,
      lastPayout: lastPaid != null
          ? DriverPayout(
              amount: lastPaid!.amountInRupees,
              date: lastPaid!.date,
              utr: '', // Not provided by API
            )
          : const DriverPayout(amount: 0, date: '', utr: ''),
      byDay: byDay,
      breakdown: breakdownRows,
    );
  }
}
