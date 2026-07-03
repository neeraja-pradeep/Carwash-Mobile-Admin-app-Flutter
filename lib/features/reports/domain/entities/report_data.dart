import 'daily_summary.dart';

/// The resolved date window echoed by every report
/// (`{ key, label, start, end }`).
class ReportPeriod {
  const ReportPeriod({
    required this.key,
    required this.label,
    required this.start,
    required this.end,
  });

  final String key;
  final String label;
  final String start;
  final String end;
}

// ─── Revenue ──────────────────────────────────────────────────────────────────

/// `/api/reports/v1/revenue/` — reuses [RevenueSummary] + [ServiceStat].
class RevenueReport {
  const RevenueReport({required this.period, required this.kpis, required this.byService});

  final ReportPeriod period;
  final RevenueSummary kpis;
  final List<ServiceStat> byService;
}

// ─── Drivers & Inspectors ─────────────────────────────────────────────────────

class DriverPerfRow {
  const DriverPerfRow({
    required this.name,
    required this.wash,
    required this.hire,
    required this.earnings,
    this.rating,
  });

  final String name;
  final int wash;
  final int hire;
  final num earnings;
  final double? rating;
}

class InspectorPerfRow {
  const InspectorPerfRow({
    required this.name,
    required this.inspections,
    required this.payout,
    this.rating,
  });

  final String name;
  final int inspections;
  final num payout;
  final double? rating;
}

/// `/api/reports/v1/drivers-inspectors/`.
class DriversReport {
  const DriversReport({
    required this.period,
    required this.activeDrivers,
    required this.hireJobs,
    required this.driverPayout,
    required this.inspectorPayout,
    required this.drivers,
    required this.inspectors,
  });

  final ReportPeriod period;
  final int activeDrivers;
  final int hireJobs;
  final num driverPayout;
  final num inspectorPayout;
  final List<DriverPerfRow> drivers;
  final List<InspectorPerfRow> inspectors;
}

// ─── Shop Performance ─────────────────────────────────────────────────────────

/// `/api/reports/v1/shop-performance/` — reuses [ShopStat] for rows.
class ShopPerformanceReport {
  const ShopPerformanceReport({
    required this.period,
    required this.shopsActive,
    required this.totalBookings,
    required this.totalRevenue,
    required this.byShop,
  });

  final ReportPeriod period;
  final int shopsActive;
  final int totalBookings;
  final num totalRevenue;
  final List<ShopStat> byShop;
}

// ─── Commission / Settlement ──────────────────────────────────────────────────

class CommissionShopRow {
  const CommissionShopRow({
    required this.shop,
    required this.gross,
    required this.commission,
  });

  final String shop;
  final num gross;
  final num commission;
}

/// `/api/reports/v1/commission/`.
class CommissionReport {
  const CommissionReport({
    required this.period,
    required this.platformCommission,
    required this.shopEarnings,
    required this.refundsDeducted,
    required this.netSettled,
    required this.byShop,
  });

  final ReportPeriod period;
  final num platformCommission;
  final num shopEarnings;
  final num refundsDeducted;
  final num netSettled;
  final List<CommissionShopRow> byShop;
}

// ─── Cancellations ────────────────────────────────────────────────────────────

class CancellationReasonRow {
  const CancellationReasonRow({required this.reason, required this.count});

  final String reason;
  final int count;
}

/// `/api/reports/v1/cancellations/`.
class CancellationsReport {
  const CancellationsReport({
    required this.period,
    required this.cancelled,
    required this.cancelRatePercent,
    required this.refundsIssued,
    required this.totalBookings,
    required this.reasons,
  });

  final ReportPeriod period;
  final int cancelled;
  final double cancelRatePercent;
  final num refundsIssued;
  final int totalBookings;
  final List<CancellationReasonRow> reasons;
}

// ─── Inspections ──────────────────────────────────────────────────────────────

class InspectionRow {
  const InspectionRow({
    required this.name,
    required this.inspections,
    required this.payout,
  });

  final String name;
  final int inspections;
  final num payout;
}

/// `/api/reports/v1/inspections/`.
class InspectionsReport {
  const InspectionsReport({
    required this.period,
    required this.inspections,
    required this.inspectorPayout,
    required this.avgFee,
    required this.activeInspectors,
    required this.rows,
  });

  final ReportPeriod period;
  final int inspections;
  final num inspectorPayout;
  final num avgFee;
  final int activeInspectors;
  final List<InspectionRow> rows;
}
