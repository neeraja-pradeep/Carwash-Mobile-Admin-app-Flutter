import '../../../../../app/config/constants.dart';
import '../../../../drivers/domain/entities/driver_earnings.dart';
import '../../../../drivers/domain/entities/driver_job.dart';
import '../../../domain/entities/worker_profile.dart';

/// Static sample driver-app data (Alappuzha demo set, verbatim from `data.jsx`
/// DRIVER_JOBS + DRIVER_EARNINGS — the signed-in driver is Manoj Kumar, fd1).
///
/// This is the ONLY place this data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class DriverAppLocalDs {
  const DriverAppLocalDs();

  /// Returns all four driver jobs (DJ-1 active carwash, DJ-2 upcoming carwash,
  /// DJ-3 upcoming driver-hire for Sandra Pius, DJ-4 completed carwash).
  Future<List<DriverJob>> fetchDriverJobs() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _driverJobs;
  }

  /// Returns Manoj Kumar's earnings for the current demo week.
  Future<DriverEarnings> fetchDriverEarnings() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _driverEarnings;
  }

  /// Returns Manoj Kumar's worker profile.
  Future<WorkerProfile> fetchWorkerProfile() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _workerProfile;
  }

  // ── Static sample data (verbatim from data.jsx DRIVER_JOBS / DRIVER_EARNINGS)

  static const List<DriverJob> _driverJobs = [
    // DJ-1 — ACTIVE: Carwash, currently Washing (fixed fare, nothing to collect)
    DriverJob(
      id: 'DJ-1',
      type: 'Carwash',
      state: DriverJobState.active,
      customer: 'Ramesh Kurup',
      phone: '+91 94470 56789',
      vehicle: 'Maruti Swift Dzire · KL-04-K-7788',
      pickup: 'Mullackal Junction, Temple Rd',
      drop: 'Same as pickup',
      shop: 'SparkleWash Mullackal',
      time: '9:00 AM',
      payout: 180,
      stage: 'Washing',
      otp: '1234',
      fare: DriverFare(
        base: 180,
        items: [],
        extra: 0,
        total: 180,
        collect: 0,
      ),
    ),

    // DJ-2 — UPCOMING: Carwash (fixed fare)
    DriverJob(
      id: 'DJ-2',
      type: 'Carwash',
      state: DriverJobState.upcoming,
      customer: 'Faisal Rahman',
      phone: '+91 97460 18822',
      vehicle: 'Honda City · KL-04-N-5512',
      pickup: 'Sea View Ward, Beach Rd',
      drop: 'Same as pickup',
      shop: 'SparkleWash Mullackal',
      time: '2:00 PM',
      payout: 180,
      stage: 'Assigned',
      otp: '1234',
      fare: DriverFare(
        base: 180,
        items: [],
        extra: 0,
        total: 180,
        collect: 0,
      ),
    ),

    // DJ-3 — UPCOMING: Driver hire, Sandra Pius, Hospital Assistance.
    // 4h planned / 5h actual → extra hour +₹120 + night allowance +₹80 =
    // collect ₹200 extra from customer.
    DriverJob(
      id: 'DJ-3',
      type: 'Driver hire',
      state: DriverJobState.upcoming,
      customer: 'Sandra Pius',
      phone: '+91 90370 18820',
      vehicle: 'Maruti Ertiga · KL-04-Q-7781',
      pickup: 'Komala Rd, near Boat Jetty',
      drop: 'City drive · 4 hrs',
      shop: '—',
      time: '5:00 PM',
      payout: 600,
      stage: 'Assigned',
      otp: '1234',
      reason: 'Hospital Assistance',
      fare: DriverFare(
        base: 600,
        plannedHours: 4,
        actualHours: 5,
        items: [
          FareItem(label: 'Extra 1 hr over 4 hr plan', amount: 120),
          FareItem(label: 'Night allowance (after 9pm)', amount: 80),
        ],
        extra: 200,
        total: 800,
        collect: 200,
      ),
    ),

    // DJ-4 — COMPLETED: Carwash (fixed fare, nothing to collect)
    DriverJob(
      id: 'DJ-4',
      type: 'Carwash',
      state: DriverJobState.completed,
      customer: 'Deepak Nair',
      phone: '+91 94950 27718',
      vehicle: 'Tata Nexon · KL-04-R-6677',
      pickup: 'Iron Bridge North',
      drop: 'Same as pickup',
      shop: 'ShineHub Iron Bridge',
      time: '8:00 AM',
      payout: 180,
      stage: 'Completed',
      otp: '1234',
      fare: DriverFare(
        base: 180,
        items: [],
        extra: 0,
        total: 180,
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
      date: '22-May-2026',
      utr: 'UPI/HDFC/55120098',
    ),
    byDay: const [
      ('Mon', 480),
      ('Tue', 540),
      ('Wed', 360),
      ('Thu', 620),
      ('Fri', 540),
      ('Sat', 0),
      ('Sun', 0),
    ],
    breakdown: const [
      EarningsBreakdownRow(label: 'Carwash jobs', count: 14, amount: 2520),
      EarningsBreakdownRow(label: 'Driver hire', count: 3, amount: 540),
      EarningsBreakdownRow(label: 'Incentives', count: 1, amount: 60),
    ],
  );

  static final WorkerProfile _workerProfile = WorkerProfile(
    id: 24,
    fullName: 'Manoj Kumar',
    phone: '+919744730021',
    email: 'manoj.k@gmail.com',
    profilePicture: 'https://cdn.bunnycdn.com/d24.jpg',
    role: 'driver',
    roleLabel: 'Wash driver',
    title: 'Detailer',
    status: WorkerStatus.active,
    online: true,
    rating: 4.7,
    licenseNumber: 'KL04 20190004821',
    jobsDone: 142,
  );
}
