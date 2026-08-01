import 'package:new_flutter_project/app/config/constants.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';

import '../../../domain/entities/shop.dart';

/// Static sample shops (from `data.jsx` lines 81–276).
///
/// This is the ONLY place shop data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class ShopsLocalDs {
  const ShopsLocalDs();

  Future<List<Shop>> fetchShops() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _shops;
  }

  // ─── Hours / slot helpers ────────────────────────────────────────────────

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Parses "9:00 AM" / "8:00 PM" → 24-h int. Returns 9 on failure.
  static int _parseHour(String s) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
        .firstMatch(s);
    if (m == null) return 9;
    int h = int.parse(m.group(1)!) % 12;
    if (m.group(3)!.toUpperCase() == 'PM') h += 12;
    return h;
  }

  // ─── Standard hours (Mon–Fri + Sat closes 9 PM, Sun off) ────────────────

  static const List<DayHours> _hoursStd = [
    DayHours(day: 'Mon', open: '9:00 AM', close: '8:00 PM', closed: false),
    DayHours(day: 'Tue', open: '9:00 AM', close: '8:00 PM', closed: false),
    DayHours(day: 'Wed', open: '9:00 AM', close: '8:00 PM', closed: false),
    DayHours(day: 'Thu', open: '9:00 AM', close: '8:00 PM', closed: false),
    DayHours(day: 'Fri', open: '9:00 AM', close: '8:00 PM', closed: false),
    DayHours(day: 'Sat', open: '9:00 AM', close: '9:00 PM', closed: false),
    DayHours(day: 'Sun', open: '—', close: '—', closed: true),
  ];

  static const List<String> _photos = [
    'assets/shop-hero.jpg',
    'assets/shop-thumb.jpg',
  ];

  // ─── Weekly slot config builder ──────────────────────────────────────────

  /// Builds per-day [WeeklyDay] list for a shop.
  /// [offDay] = 'Sun' or 'Mon' depending on the shop.
  /// [offSlotsFn] maps day name → list of off-slot hours (empty otherwise).
  static List<WeeklyDay> _buildWeekly(
    String offDay, {
    required String stdOpen,
    List<int> Function(String day)? offSlotsFn,
  }) {
    return _weekdays.asMap().entries.map((entry) {
      final day = entry.value;
      final closed = day == offDay;
      return WeeklyDay(
        day: day,
        weekday: entry.key,
        closed: closed,
        open: _parseHour(stdOpen),
        close: _parseHour(day == 'Sat' ? '9:00 PM' : '8:00 PM'),
        offSlots: closed ? [] : (offSlotsFn?.call(day) ?? []),
      );
    }).toList();
  }

  // ─── Per-vehicle-type pricing helper ─────────────────────────────────────

  /// Maps 5-element row list [[price, min, active?]] to a [ServicePricing] list
  /// over [kVehicleTypes].
  static List<ServicePricing> _mtx(List<List<int>> rows) {
    return List.generate(kVehicleTypes.length, (i) {
      final r = rows[i];
      return ServicePricing(
        type: kVehicleTypes[i],
        price: r[0],
        minutes: r[1],
        active: r.length > 2 ? r[2] != 0 : true,
      );
    });
  }

  // ─── SHOPS ───────────────────────────────────────────────────────────────

  static final List<Shop> _shops = [
    // s1 — SparkleWash Mullackal
    Shop(
      id: 's1',
      name: 'SparkleWash Mullackal',
      area: 'Mullackal Junction',
      ownerName: 'Rajesh Pillai',
      ownerPhone: '+91 98470 33120',
      shopPhone: '+91 477 226 1180',
      address: 'Temple Rd, Mullackal Junction, Alappuzha 688011',
      rating: 4.6,
      reviews: 128,
      todayBookings: 12,
      cap: 20,
      avgServiceMin: 38,
      active: true,
      vehicleTypes: const [
        'Hatchback', 'Sedan', 'Compact SUV', 'SUV', 'Premium SUV',
      ],
      commission: const Commission(mode: CommissionMode.percentage, pct: 15),
      bank: const BankDetails(
        accName: 'Sparkle Auto Care',
        accNo: '50100 2284 1190',
        ifsc: 'HDFC0000456',
        upi: 'sparklewash@okhdfc',
        gstin: '32ABCFS1234K1Z5',
        pan: 'ABCFS1234K',
      ),
      hours: _hoursStd,
      photos: _photos,
      onboarded: const EditMeta(date: '08-Jan-2026', by: 'Anand'),
      lastEdited: const EditMeta(date: '21-May-2026', by: 'Vishnu'),
      services: [
        ShopService(
          id: 'sv1',
          name: 'Exterior Wash',
          description: 'High-pressure foam wash + tyre dressing',
          samePrice: false,
          active: true,
          pricing: _mtx([
            [250, 30], [320, 35], [350, 40], [400, 45], [450, 50],
          ]),
        ),
        const ShopService(
          id: 'sv2',
          name: 'Interior Vacuum',
          description: 'Cabin vacuum + dashboard wipe',
          samePrice: true,
          flatPrice: 180,
          flatMinutes: 25,
          active: true,
        ),
        ShopService(
          id: 'sv3',
          name: 'Full Detail',
          description: 'Exterior + interior deep clean + polish',
          samePrice: false,
          active: true,
          pricing: _mtx([
            [900, 90], [1000, 95], [1150, 105], [1300, 115], [1500, 130],
          ]),
        ),
        const ShopService(
          id: 'sv4',
          name: 'Wax Polish',
          description: 'Carnauba wax hand-applied',
          samePrice: true,
          flatPrice: 350,
          flatMinutes: 30,
          active: false,
        ),
      ],
      settlement: Settlement(
        lastSettled: '12-May-2026',
        lifetimePaid: 84500,
        pending: const [
          PendingSettlement(
            date: '26-May', bookingId: 'DD-KL-20260526-0031',
            gross: 650, commission: 98, refund: 0,
          ),
          PendingSettlement(
            date: '27-May', bookingId: 'DD-KL-20260527-0019',
            gross: 500, commission: 75, refund: 0,
          ),
          PendingSettlement(
            date: '28-May', bookingId: 'DD-KL-20260528-0024',
            gross: 670, commission: 101, refund: 150,
          ),
          PendingSettlement(
            date: '29-May', bookingId: 'DD-KL-20260529-0042',
            gross: 500, commission: 75, refund: 0,
          ),
        ],
        history: const [
          SettlementHistoryItem(
            period: '1–12 May 2026', net: 6240,
            status: 'Paid', utr: 'HDFC8841992001',
          ),
          SettlementHistoryItem(
            period: '21–30 Apr 2026', net: 5180,
            status: 'Paid', utr: 'HDFC8830014477',
          ),
        ],
      ),
      weekly: _buildWeekly(
        'Sun',
        stdOpen: '9:00 AM',
        offSlotsFn: (day) =>
            (day == 'Mon' || day == 'Tue') ? [13] : [],
      ),
      slotCapacityEnabled: true,
      slotCap: 3,
    ),

    // s2 — AquaShine Thathampally (Mon off instead of Sun)
    Shop(
      id: 's2',
      name: 'AquaShine Thathampally',
      area: 'Thathampally Beach Rd',
      ownerName: 'Suresh Kumar',
      ownerPhone: '+91 99461 22087',
      shopPhone: '+91 477 224 3390',
      address: 'Beach Rd, Thathampally, Alappuzha 688013',
      rating: 4.3,
      reviews: 74,
      todayBookings: 16,
      cap: 18,
      avgServiceMin: 32,
      active: true,
      vehicleTypes: const ['Hatchback', 'Sedan', 'Compact SUV'],
      commission: const Commission(mode: CommissionMode.flat, flat: 40),
      bank: const BankDetails(
        accName: 'AquaShine Services',
        accNo: '3389 1100 4521',
        ifsc: 'SBIN0011223',
        upi: 'aquashine@oksbi',
        gstin: '',
        pan: 'DKLPS9087H',
      ),
      hours: _hoursStd,
      photos: _photos,
      onboarded: const EditMeta(date: '02-Feb-2026', by: 'Vishnu'),
      lastEdited: const EditMeta(date: '18-May-2026', by: 'Anand'),
      services: [
        ShopService(
          id: 'sv5',
          name: 'Exterior Wash',
          description: 'Foam wash + dry',
          samePrice: false,
          active: true,
          pricing: _mtx([
            [230, 30], [250, 32], [300, 38], [0, 0, 0], [0, 0, 0],
          ]),
        ),
        const ShopService(
          id: 'sv6',
          name: 'Underbody Wash',
          description: 'Anti-rust underbody jet wash',
          samePrice: true,
          flatPrice: 150,
          flatMinutes: 20,
          active: true,
        ),
      ],
      settlement: Settlement(
        lastSettled: '20-May-2026',
        lifetimePaid: 41200,
        pending: const [
          PendingSettlement(
            date: '27-May', bookingId: 'DD-KL-20260527-0022',
            gross: 250, commission: 40, refund: 0,
          ),
          PendingSettlement(
            date: '29-May', bookingId: 'DD-KL-20260529-0041',
            gross: 250, commission: 40, refund: 0,
          ),
        ],
        history: const [
          SettlementHistoryItem(
            period: '10–20 May 2026', net: 3920,
            status: 'Paid', utr: 'SBIN5520119003',
          ),
        ],
      ),
      weekly: _buildWeekly('Mon', stdOpen: '9:00 AM'),
      slotCapacityEnabled: false,
      slotCap: 3,
    ),

    // s3 — GleamPro Vazhicherry
    Shop(
      id: 's3',
      name: 'GleamPro Vazhicherry',
      area: 'Vazhicherry Ward',
      ownerName: 'Fathima Beevi',
      ownerPhone: '+91 97448 55012',
      shopPhone: '+91 477 223 7745',
      address: 'CCNB Rd, Vazhicherry Ward, Alappuzha 688012',
      rating: 4.8,
      reviews: 203,
      todayBookings: 9,
      cap: 22,
      avgServiceMin: 45,
      active: true,
      vehicleTypes: const [
        'Hatchback', 'Sedan', 'Compact SUV', 'SUV', 'Premium SUV',
      ],
      commission: const Commission(
        mode: CommissionMode.floor, pct: 15, floor: 30,
      ),
      bank: const BankDetails(
        accName: 'GleamPro Detailing',
        accNo: '9920 4471 0038',
        ifsc: 'ICIC0004412',
        upi: 'gleampro@okicici',
        gstin: '32FATPB7766L1Z2',
        pan: 'FATPB7766L',
      ),
      hours: _hoursStd,
      photos: _photos,
      onboarded: const EditMeta(date: '15-Dec-2025', by: 'Anand'),
      lastEdited: const EditMeta(date: '24-May-2026', by: 'Anand'),
      services: [
        ShopService(
          id: 'sv7',
          name: 'Full Detail',
          description: 'Showroom-grade detail with clay bar',
          samePrice: false,
          active: true,
          pricing: _mtx([
            [950, 90], [1050, 95], [1200, 105], [1350, 120], [1600, 135],
          ]),
        ),
        const ShopService(
          id: 'sv8',
          name: 'Exterior Wash',
          description: 'Premium foam + spot-free rinse',
          samePrice: true,
          flatPrice: 300,
          flatMinutes: 35,
          active: true,
        ),
      ],
      settlement: Settlement(
        lastSettled: '24-May-2026',
        lifetimePaid: 132800,
        pending: const [
          PendingSettlement(
            date: '29-May', bookingId: 'DD-KL-20260529-0039',
            gross: 500, commission: 75, refund: 0,
          ),
        ],
        history: const [
          SettlementHistoryItem(
            period: '15–24 May 2026', net: 8760,
            status: 'Paid', utr: 'ICIC7741200911',
          ),
        ],
      ),
      weekly: _buildWeekly('Sun', stdOpen: '9:00 AM'),
      slotCapacityEnabled: false,
      slotCap: 3,
    ),

    // s4 — BlueWave Komala Rd
    Shop(
      id: 's4',
      name: 'BlueWave Komala Rd',
      area: 'Komala Road',
      ownerName: 'Joseph Mathew',
      ownerPhone: '+91 98952 71140',
      shopPhone: '+91 477 225 9012',
      address: 'Komala Rd, near Boat Jetty, Alappuzha 688001',
      rating: 4.1,
      reviews: 56,
      todayBookings: 18,
      cap: 20,
      avgServiceMin: 36,
      active: true,
      vehicleTypes: const ['Hatchback', 'Sedan', 'SUV'],
      commission: const Commission(mode: CommissionMode.percentage, pct: 12),
      bank: const BankDetails(
        accName: 'BlueWave Carwash',
        accNo: '1120 8830 4490',
        ifsc: 'FDRL0001088',
        upi: 'bluewave@okfederal',
        gstin: '',
        pan: 'JMQPM3340Q',
      ),
      hours: _hoursStd,
      photos: _photos,
      onboarded: const EditMeta(date: '20-Mar-2026', by: 'Vishnu'),
      lastEdited: const EditMeta(date: '12-May-2026', by: 'Vishnu'),
      services: [
        ShopService(
          id: 'sv9',
          name: 'Exterior Wash',
          description: 'Standard wash',
          samePrice: false,
          active: true,
          pricing: _mtx([
            [240, 30], [320, 35], [0, 0, 0], [400, 42], [0, 0, 0],
          ]),
        ),
      ],
      settlement: Settlement(
        lastSettled: '11-May-2026',
        lifetimePaid: 28900,
        pending: const [
          PendingSettlement(
            date: '29-May', bookingId: 'DD-KL-20260529-0045',
            gross: 600, commission: 72, refund: 0,
          ),
          PendingSettlement(
            date: '28-May', bookingId: 'DD-KL-20260528-0017',
            gross: 320, commission: 38, refund: 320,
          ),
        ],
        history: const [
          SettlementHistoryItem(
            period: '1–11 May 2026', net: 4110,
            status: 'Paid', utr: 'FDRL3301889220',
          ),
        ],
      ),
      weekly: _buildWeekly('Sun', stdOpen: '9:00 AM'),
      slotCapacityEnabled: false,
      slotCap: 3,
    ),

    // s5 — ShineHub Iron Bridge (inactive)
    Shop(
      id: 's5',
      name: 'ShineHub Iron Bridge',
      area: 'Iron Bridge, North',
      ownerName: 'Abdul Latheef',
      ownerPhone: '+91 90376 09981',
      shopPhone: '+91 477 228 4456',
      address: 'Iron Bridge North, Alappuzha 688001',
      rating: 3.9,
      reviews: 31,
      todayBookings: 0,
      cap: 16,
      avgServiceMin: 34,
      active: false,
      vehicleTypes: const ['Hatchback', 'Sedan'],
      commission: const Commission(mode: CommissionMode.flat, flat: 50),
      bank: const BankDetails(
        accName: 'ShineHub Auto',
        accNo: '7740 2219 0034',
        ifsc: 'CNRB0002281',
        upi: 'shinehub@okcanara',
        gstin: '',
        pan: 'ABLPL5521M',
      ),
      hours: _hoursStd,
      photos: _photos,
      onboarded: const EditMeta(date: '05-Apr-2026', by: 'Anand'),
      lastEdited: const EditMeta(date: '06-Apr-2026', by: 'Anand'),
      services: [
        const ShopService(
          id: 'sv10',
          name: 'Exterior Wash',
          description: 'Basic wash',
          samePrice: true,
          flatPrice: 300,
          flatMinutes: 35,
          active: true,
        ),
      ],
      settlement: Settlement(
        lastSettled: '—',
        lifetimePaid: 1750,
        pending: const [],
        history: const [
          SettlementHistoryItem(
            period: '1–5 Apr 2026', net: 1750,
            status: 'Paid', utr: 'CNRB2218003311',
          ),
        ],
      ),
      weekly: _buildWeekly('Sun', stdOpen: '9:00 AM'),
      slotCapacityEnabled: false,
      slotCap: 3,
    ),
  ];
}
