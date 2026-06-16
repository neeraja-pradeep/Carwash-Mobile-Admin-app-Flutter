/// A per-shop booking/revenue breakdown row.
class ShopStat {
  const ShopStat({
    required this.shop,
    required this.bookings,
    required this.revenue,
  });

  final String shop;
  final int bookings;
  final num revenue;
}

/// A per-service booking/revenue breakdown row.
class ServiceStat {
  const ServiceStat({
    required this.name,
    required this.count,
    required this.revenue,
  });

  final String name;
  final int count;
  final num revenue;
}

/// A top-coupon usage row.
class CouponStat {
  const CouponStat({required this.code, required this.used});

  final String code;
  final int used;
}

/// Per-driver performance row.
class DriverStat {
  const DriverStat({
    required this.name,
    required this.role,
    required this.jobs,
    required this.hireJobs,
    required this.earnings,
    this.rating,
    required this.online,
  });

  final String name;
  final String role;
  final int jobs;
  final int hireJobs;
  final num earnings;
  final double? rating;
  final bool online;
}

/// Per-inspector performance row.
class InspectorStat {
  const InspectorStat({
    required this.name,
    required this.inspections,
    required this.earnings,
    this.rating,
    required this.online,
  });

  final String name;
  final int inspections;
  final num earnings;
  final double? rating;
  final bool online;
}

/// Team aggregate totals.
class TeamTotals {
  const TeamTotals({
    required this.activeDrivers,
    required this.hireJobs,
    required this.inspections,
    required this.driverPayout,
    required this.inspectorPayout,
  });

  final int activeDrivers;
  final int hireJobs;
  final int inspections;
  final num driverPayout;
  final num inspectorPayout;
}

/// Revenue summary.
class RevenueSummary {
  const RevenueSummary({
    required this.gross,
    required this.commission,
    required this.refunds,
    required this.net,
  });

  final num gross;
  final num commission;
  final num refunds;
  final num net;
}

/// Booking counts.
class BookingCounts {
  const BookingCounts({
    required this.total,
    required this.completed,
    required this.active,
    required this.cancelled,
    required this.newCount,
  });

  final int total;
  final int completed;
  final int active;
  final int cancelled;
  final int newCount;
}

/// Daily summary — the root aggregate used by all 6 report views.
class DailySummary {
  const DailySummary({
    required this.date,
    required this.bookings,
    required this.revenue,
    required this.newCustomers,
    required this.avgRating,
    required this.byShop,
    required this.byService,
    required this.hourly,
    required this.topCoupons,
    required this.byDriver,
    required this.byInspector,
    required this.teamTotals,
  });

  final String date;
  final BookingCounts bookings;
  final RevenueSummary revenue;
  final int newCustomers;
  final double avgRating;
  final List<ShopStat> byShop;
  final List<ServiceStat> byService;
  final List<int> hourly;
  final List<CouponStat> topCoupons;
  final List<DriverStat> byDriver;
  final List<InspectorStat> byInspector;
  final TeamTotals teamTotals;
}
