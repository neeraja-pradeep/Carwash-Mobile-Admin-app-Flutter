import 'package:new_flutter_project/app/config/constants.dart';

import '../../../domain/entities/daily_summary.dart';

/// Static sample daily summary (Alappuzha demo set, from `data.jsx`).
class ReportsLocalDs {
  const ReportsLocalDs();

  Future<DailySummary> fetchDailySummary() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _summary;
  }

  static const DailySummary _summary = DailySummary(
    date: '29 May 2026',
    bookings: BookingCounts(
      total: 9,
      completed: 3,
      active: 4,
      cancelled: 1,
      newCount: 1,
    ),
    revenue: RevenueSummary(
      gross: 4520,
      commission: 642,
      refunds: 1100,
      net: 2778,
    ),
    newCustomers: 2,
    avgRating: 4.5,
    byShop: [
      ShopStat(shop: 'SparkleWash Mullackal', bookings: 12, revenue: 1670),
      ShopStat(shop: 'AquaShine Thathampally', bookings: 16, revenue: 500),
      ShopStat(shop: 'GleamPro Vazhicherry', bookings: 9, revenue: 1400),
      ShopStat(shop: 'BlueWave Komala Rd', bookings: 18, revenue: 600),
      ShopStat(shop: 'ShineHub Iron Bridge', bookings: 0, revenue: 350),
    ],
    byService: [
      ServiceStat(name: 'Exterior Wash', count: 5, revenue: 1690),
      ServiceStat(name: 'Full Detail', count: 2, revenue: 1800),
      ServiceStat(name: 'Interior Vacuum', count: 1, revenue: 180),
      ServiceStat(name: 'Underbody Wash', count: 1, revenue: 200),
    ],
    hourly: [0, 0, 0, 0, 0, 0, 1, 2, 3, 2, 1, 2, 1, 0, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0],
    topCoupons: [
      CouponStat(code: 'FIRST50', used: 4),
      CouponStat(code: 'MONSOON100', used: 2),
    ],
    byDriver: [
      DriverStat(
        name: 'Manoj Kumar',
        role: 'Wash driver',
        jobs: 3,
        hireJobs: 0,
        earnings: 540,
        rating: 4.7,
        online: true,
      ),
      DriverStat(
        name: 'Sreejith P',
        role: 'Wash + hire driver',
        jobs: 2,
        hireJobs: 1,
        earnings: 760,
        rating: 4.5,
        online: true,
      ),
      DriverStat(
        name: 'Rahim Basheer',
        role: 'Wash driver',
        jobs: 0,
        hireJobs: 0,
        earnings: 0,
        rating: null,
        online: false,
      ),
    ],
    byInspector: [
      InspectorStat(
        name: 'Ravi Menon',
        inspections: 2,
        earnings: 1600,
        rating: 4.8,
        online: true,
      ),
      InspectorStat(
        name: 'Salim K',
        inspections: 0,
        earnings: 0,
        rating: 4.4,
        online: false,
      ),
    ],
    teamTotals: TeamTotals(
      activeDrivers: 2,
      hireJobs: 1,
      inspections: 2,
      driverPayout: 1300,
      inspectorPayout: 1600,
    ),
  );
}
