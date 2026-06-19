import '../../../../../app/config/constants.dart';
import '../../../../drivers/domain/entities/driver_earnings.dart';
import '../../../../drivers/domain/entities/driver_job.dart';

/// Static sample driver-app data (Alappuzha demo set, from `data.jsx`
/// DRIVER_JOBS + DRIVER_EARNINGS).
///
/// This is the ONLY place this data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class DriverAppLocalDs {
  const DriverAppLocalDs();

  /// Returns all four driver jobs (DJ-1 active, DJ-2 upcoming, DJ-3 upcoming
  /// driver-hire, DJ-4 completed).
  Future<List<DriverJob>> fetchDriverJobs() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _driverJobs;
  }

  /// Returns Manoj Kumar's earnings for the current demo week.
  Future<DriverEarnings> fetchDriverEarnings() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _driverEarnings;
  }

  // ── Static sample data (verbatim from data.jsx DRIVER_JOBS / DRIVER_EARNINGS)

  static const List<DriverJob> _driverJobs = [
    // DJ-1 — ACTIVE: Carwash, currently Washing
    DriverJob(
      id: 'DJ-1',
      type: 'Carwash',
      state: DriverJobState.active,
      customer: 'Faisal Rahman',
      phone: '+91 95550 12345',
      vehicle: 'KL-04-AB-1234 · Swift Dzire (White)',
      pickup: 'Mullackal, Alappuzha',
      drop: 'SparkleWash Mullackal',
      shop: 'SparkleWash Mullackal',
      time: '9:00 AM',
      payout: 180,
      stage: 'Washing',
      otp: '5821',
      fare: DriverFare(
        base: 180,
        items: [],
        extra: 0,
        total: 180,
        collect: 0,
      ),
    ),

    // DJ-2 — UPCOMING: Carwash
    DriverJob(
      id: 'DJ-2',
      type: 'Carwash',
      state: DriverJobState.upcoming,
      customer: 'Priya Nair',
      phone: '+91 98470 67890',
      vehicle: 'KL-04-CD-5678 · Baleno (Silver)',
      pickup: 'Thathampally, Alappuzha',
      drop: 'AquaShine Thathampally',
      shop: 'AquaShine Thathampally',
      time: '11:30 AM',
      payout: 200,
      stage: 'Assigned',
      otp: '3047',
      fare: DriverFare(
        base: 200,
        items: [],
        extra: 0,
        total: 200,
        collect: 0,
      ),
    ),

    // DJ-3 — UPCOMING: Driver hire, Sandra Pius, extra charge ₹200 to collect
    DriverJob(
      id: 'DJ-3',
      type: 'Driver hire',
      state: DriverJobState.upcoming,
      customer: 'Sandra Pius',
      phone: '+91 94470 11223',
      vehicle: 'KL-07-EF-9012 · Innova Crysta (Grey)',
      pickup: 'Hospital Jn, Alappuzha',
      drop: 'Ernakulam Medical Centre',
      shop: 'Driver Hire Service',
      time: '2:00 PM',
      payout: 620,
      stage: 'Assigned',
      otp: '7391',
      fare: DriverFare(
        base: 420,
        items: [
          FareItem(label: 'Night allowance', amount: 150),
          FareItem(label: 'Toll charges', amount: 50),
        ],
        extra: 200,
        total: 820,
        collect: 200,
        plannedHours: 4,
      ),
    ),

    // DJ-4 — COMPLETED: Carwash
    DriverJob(
      id: 'DJ-4',
      type: 'Carwash',
      state: DriverJobState.completed,
      customer: 'Deepak Nair',
      phone: '+91 94950 27718',
      vehicle: 'KL-04-GH-3456 · Creta (Blue)',
      pickup: 'Iron Bridge, Alappuzha',
      drop: 'ShineHub Iron Bridge',
      shop: 'ShineHub Iron Bridge',
      time: '7:30 AM',
      payout: 160,
      stage: 'Completed',
      otp: '2214',
      fare: DriverFare(
        base: 160,
        items: [],
        extra: 0,
        total: 160,
        collect: 0,
      ),
    ),
  ];

  static final DriverEarnings _driverEarnings = DriverEarnings(
    todayTotal: 540,
    weekTotal: 3120,
    pending: 720,
    lastPayout: const DriverPayout(
      amount: 2890,
      date: '22 May 2026',
      utr: 'UTR4982017736',
    ),
    byDay: const [
      ('Mon', 320),
      ('Tue', 480),
      ('Wed', 540),
      ('Thu', 620),
      ('Fri', 400),
      ('Sat', 760),
      ('Sun', 0),
    ],
    breakdown: const [
      EarningsBreakdownRow(label: 'Carwash jobs', count: 14, amount: 2520),
      EarningsBreakdownRow(label: 'Driver hire', count: 4, amount: 480),
      EarningsBreakdownRow(label: 'Incentives', count: 1, amount: 120),
    ],
  );

  /// Monthly (June 2026) earnings summary — used by the Month period view.
  static final DriverEarnings _driverEarningsMonth = DriverEarnings(
    todayTotal: 540,
    weekTotal: 11480,
    pending: 1240,
    lastPayout: const DriverPayout(
      amount: 2890,
      date: '22 May 2026',
      utr: 'UTR4982017736',
    ),
    byDay: const [
      // Labelled by week for the bar chart in the Month view.
      ('W1', 2640),
      ('W2', 3180),
      ('W3', 2860),
      ('W4', 2800),
    ],
    breakdown: const [
      EarningsBreakdownRow(label: 'Carwash jobs', count: 52, amount: 9360),
      EarningsBreakdownRow(label: 'Driver hire', count: 14, amount: 1680),
      EarningsBreakdownRow(label: 'Incentives', count: 3, amount: 440),
    ],
  );

  /// Returns the earnings summary for the given [period]:
  /// `'week'` (default) or `'month'`.
  Future<DriverEarnings> fetchDriverEarningsForPeriod(String period) async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return period == 'month' ? _driverEarningsMonth : _driverEarnings;
  }
}
