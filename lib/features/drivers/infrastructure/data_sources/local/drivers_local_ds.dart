import '../../../../../app/config/constants.dart';
import '../../../domain/entities/field_driver.dart';
import '../../../domain/entities/team_member.dart';

/// Static sample driver data (Alappuzha demo set, from `data.jsx`).
///
/// This is the ONLY place driver data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class DriversLocalDs {
  const DriversLocalDs();

  /// Returns all four hired field drivers (fd1–fd4).
  Future<List<FieldDriver>> fetchFieldDrivers() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _fieldDrivers;
  }

  /// Returns the two founders (Anand, Vishnu) as [TeamMember].
  Future<List<TeamMember>> fetchFounders() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _founders;
  }

  /// Returns the two inspectors (Ravi Menon, Salim K) as [TeamMember].
  Future<List<TeamMember>> fetchInspectors() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _inspectors;
  }

  // ── Static sample data (verbatim from data.jsx FIELD_DRIVERS / DRIVERS /
  //    INSPECTORS) ──────────────────────────────────────────────────────────

  static final List<FieldDriver> _fieldDrivers = [
    // fd1 — Manoj Kumar, ACTIVE, on Sandra's driver-hire trip, moving
    FieldDriver(
      id: 'fd1',
      name: 'Manoj Kumar',
      phone: '+91 97447 30021',
      email: 'manoj.k@gmail.com',
      status: DriverStatus.active,
      role: 'Wash driver',
      joined: '12-Feb-2026',
      license: const DriverLicense(
        number: 'KL04 20190004821',
        expiry: '08-2029',
        verified: true,
      ),
      rating: 4.7,
      jobsDone: 142,
      vehicleClasses: const ['Hatchback', 'Sedan', 'Compact SUV'],
      today: const DriverPeriodStat(jobs: 3, earnings: 540),
      week: const DriverPeriodStat(jobs: 18, earnings: 3120),
      documents: const [
        DriverDocument(
          id: 'dc1',
          type: 'Driving License',
          front: true,
          back: true,
        ),
        DriverDocument(
          id: 'dc2',
          type: 'Aadhaar Card',
          front: true,
          back: true,
        ),
        DriverDocument(
          id: 'dc3',
          type: 'Police Verification',
          front: true,
          back: false,
        ),
      ],
      currentJob: const DriverCurrentJob(
        bookingId: 'SR-DR-20260529-012',
        type: 'Driver hire',
        customer: 'Sandra Pius',
        stage: 'On trip · Hospital Assistance',
        location: LiveLocation(
          label: 'NH66, near Kalarcode',
          moving: true,
          lastUpdate: 'just now',
        ),
      ),
    ),

    // fd2 — Sreejith P, ACTIVE, on Faisal carwash at shop, static
    FieldDriver(
      id: 'fd2',
      name: 'Sreejith P',
      phone: '+91 90745 11882',
      email: 'sreejith.p@gmail.com',
      status: DriverStatus.active,
      role: 'Wash + hire driver',
      joined: '02-Mar-2026',
      license: const DriverLicense(
        number: 'KL04 20200013344',
        expiry: '11-2030',
        verified: true,
      ),
      rating: 4.5,
      jobsDone: 96,
      vehicleClasses: const ['Hatchback', 'Sedan', 'SUV', 'Premium SUV'],
      today: const DriverPeriodStat(jobs: 2, earnings: 760),
      week: const DriverPeriodStat(jobs: 14, earnings: 4180),
      documents: const [
        DriverDocument(
          id: 'dc4',
          type: 'Driving License',
          front: true,
          back: true,
        ),
        DriverDocument(
          id: 'dc5',
          type: 'Aadhaar Card',
          front: true,
          back: false,
        ),
      ],
      currentJob: const DriverCurrentJob(
        bookingId: 'DD-KL-20260529-0044',
        type: 'Carwash',
        customer: 'Faisal Rahman',
        stage: 'Washing',
        location: LiveLocation(
          label: 'SparkleWash Mullackal (at shop)',
          moving: false,
          lastUpdate: '3 min ago',
        ),
      ),
    ),

    // fd3 — Rahim Basheer, INVITED, no job, license unverified
    FieldDriver(
      id: 'fd3',
      name: 'Rahim Basheer',
      phone: '+91 98951 67200',
      email: '',
      status: DriverStatus.invited,
      role: 'Wash driver',
      joined: '29-May-2026',
      license: const DriverLicense(
        number: 'KL04 20210099210',
        expiry: '03-2031',
        verified: false,
      ),
      rating: null,
      jobsDone: 0,
      vehicleClasses: const ['Hatchback', 'Sedan'],
      today: const DriverPeriodStat(jobs: 0, earnings: 0),
      week: const DriverPeriodStat(jobs: 0, earnings: 0),
      documents: const [],
    ),

    // fd4 — Jithin Raj, SUSPENDED
    FieldDriver(
      id: 'fd4',
      name: 'Jithin Raj',
      phone: '+91 94470 55013',
      email: 'jithin.raj@gmail.com',
      status: DriverStatus.suspended,
      role: 'Wash driver',
      joined: '18-Jan-2026',
      license: const DriverLicense(
        number: 'KL04 20180007765',
        expiry: '06-2026',
        verified: true,
      ),
      rating: 3.9,
      jobsDone: 61,
      vehicleClasses: const ['Hatchback'],
      today: const DriverPeriodStat(jobs: 0, earnings: 0),
      week: const DriverPeriodStat(jobs: 0, earnings: 0),
      documents: const [
        DriverDocument(
          id: 'dc6',
          type: 'Driving License',
          front: true,
          back: true,
        ),
      ],
    ),
  ];

  // DRIVERS from data.jsx (founders)
  static const List<TeamMember> _founders = [
    TeamMember(
      id: 'd1',
      name: 'Anand',
      role: 'founder',
      phone: '+91 98470 22119',
      active: true,
    ),
    TeamMember(
      id: 'd2',
      name: 'Vishnu',
      role: 'co-founder',
      phone: '+91 90745 88210',
      active: true,
    ),
  ];

  // INSPECTORS from data.jsx
  static const List<TeamMember> _inspectors = [
    TeamMember(
      id: 'in1',
      name: 'Ravi Menon',
      role: 'inspector',
      phone: '+91 98470 77231',
      active: true,
    ),
    TeamMember(
      id: 'in2',
      name: 'Salim K',
      role: 'inspector',
      phone: '+91 90745 33890',
      active: true,
    ),
  ];
}
