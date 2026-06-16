import '../../../../../app/config/constants.dart';
import '../../../../../core/status/booking_status.dart';
import '../../../../../core/status/payment_status.dart';
import '../../../domain/entities/booking.dart';

/// Static sample bookings from `data.jsx` BOOKINGS (lines 278-434).
///
/// The 9 bookings cover the full booking lifecycle — washing, new, done,
/// returning, assigned, going, completed, cancelled, completed.
/// This is the ONLY place booking data lives today; in the API phase a
/// remote data source + Hive cache plug in behind the same repository
/// contract — the UI and providers stay unchanged.
class BookingsLocalDs {
  const BookingsLocalDs();

  Future<List<Booking>> fetchBookings() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _bookings;
  }

  static const List<Booking> _bookings = [
    Booking(
      id: 'DD-KL-20260529-0042',
      status: BookingStatus.washing,
      customer: BookingParty(
        name: 'Ramesh Kurup',
        phone: '+91 94470 56789',
      ),
      vehicle: Vehicle(
        make: 'Maruti',
        model: 'Swift Dzire',
        type: 'Sedan',
        plate: 'KL-04-K-7788',
      ),
      pickup: RoutePoint(
        address: 'Mullackal Junction, near Temple Rd, Alappuzha 688011',
        time: '9:00 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '11:30 AM',
        sameAsPickup: true,
      ),
      shopId: 's1',
      driverId: 'd1',
      services: [
        BookingService(name: 'Exterior Wash', price: 320, minutes: 35),
        BookingService(name: 'Interior Vacuum', price: 180, minutes: 25),
      ],
      total: 500,
      payment: PaymentStatus.paid,
      createdAt: '8:42 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 8:42 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.assigned,
          at: '29 May, 8:48 AM',
          by: 'Anand (founder)',
        ),
        TimelineEntry(
          status: BookingStatus.going,
          at: '29 May, 8:55 AM',
          by: 'Anand',
        ),
        TimelineEntry(
          status: BookingStatus.picked,
          at: '29 May, 9:06 AM',
          by: 'Anand',
        ),
        TimelineEntry(
          status: BookingStatus.atShop,
          at: '29 May, 9:24 AM',
          by: 'Anand',
        ),
        TimelineEntry(
          status: BookingStatus.washing,
          at: '29 May, 9:29 AM',
          by: 'Auto-advance',
        ),
      ],
      damage: DamageReport(
        pickup: DamageCheck(
          checked: true,
          issues: false,
          note: 'Clean, no visible damage',
        ),
      ),
      notes: 'Customer requested extra care on alloy wheels. Gate code #4421.',
    ),
    Booking(
      id: 'DD-KL-20260529-0048',
      status: BookingStatus.created,
      customer: BookingParty(
        name: 'Priya Menon',
        phone: '+91 98470 11234',
      ),
      vehicle: Vehicle(
        make: 'Hyundai',
        model: 'i20',
        type: 'Hatchback',
        plate: 'KL-04-AB-1234',
      ),
      pickup: RoutePoint(
        address: 'Thathampally Beach Rd, near Lighthouse, Alappuzha 688013',
        time: '4:15 PM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '6:00 PM',
        sameAsPickup: true,
      ),
      shopId: 's2',
      driverId: null,
      services: [
        BookingService(name: 'Exterior Wash', price: 250, minutes: 30),
      ],
      total: 250,
      payment: PaymentStatus.paid,
      createdAt: '3:58 PM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 3:58 PM',
          by: 'Customer app',
        ),
      ],
      damage: DamageReport(),
      notes: '',
    ),
    Booking(
      id: 'DD-KL-20260529-0046',
      status: BookingStatus.done,
      customer: BookingParty(
        name: 'Anitha Thomas',
        phone: '+91 95440 33871',
      ),
      vehicle: Vehicle(
        make: 'Kia',
        model: 'Seltos',
        type: 'Compact SUV',
        plate: 'KL-04-M-2201',
      ),
      pickup: RoutePoint(
        address: 'Vazhicherry Ward, CCNB Rd, Alappuzha 688012',
        time: '11:00 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '1:30 PM',
        sameAsPickup: true,
      ),
      shopId: 's3',
      driverId: 'd2',
      services: [
        BookingService(name: 'Full Detail', price: 900, minutes: 90),
      ],
      total: 900,
      payment: PaymentStatus.paid,
      createdAt: '10:21 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 10:21 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.assigned,
          at: '29 May, 10:30 AM',
          by: 'Vishnu (co-founder)',
        ),
        TimelineEntry(
          status: BookingStatus.washing,
          at: '29 May, 11:35 AM',
          by: 'Auto-advance',
        ),
        TimelineEntry(
          status: BookingStatus.done,
          at: '29 May, 1:05 PM',
          by: 'Vishnu',
        ),
      ],
      damage: DamageReport(
        pickup: DamageCheck(
          checked: true,
          issues: false,
          note: 'Clean',
        ),
      ),
      notes: '',
    ),
    Booking(
      id: 'DD-KL-20260529-0045',
      status: BookingStatus.returning,
      customer: BookingParty(
        name: 'Sajan Varghese',
        phone: '+91 99950 71240',
      ),
      vehicle: Vehicle(
        make: 'Mahindra',
        model: 'Thar',
        type: 'SUV',
        plate: 'KL-04-T-9090',
      ),
      pickup: RoutePoint(
        address: 'Komala Rd, near Boat Jetty, Alappuzha 688001',
        time: '10:30 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '1:00 PM',
        sameAsPickup: true,
      ),
      shopId: 's4',
      driverId: 'd1',
      services: [
        BookingService(name: 'Exterior Wash', price: 400, minutes: 40),
        BookingService(name: 'Underbody Wash', price: 200, minutes: 20),
      ],
      total: 600,
      payment: PaymentStatus.paid,
      createdAt: '9:50 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 9:50 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.assigned,
          at: '29 May, 9:58 AM',
          by: 'Anand (founder)',
        ),
        TimelineEntry(
          status: BookingStatus.done,
          at: '29 May, 12:20 PM',
          by: 'Anand',
        ),
        TimelineEntry(
          status: BookingStatus.returning,
          at: '29 May, 12:34 PM',
          by: 'Anand',
        ),
      ],
      damage: DamageReport(
        pickup: DamageCheck(
          checked: true,
          issues: true,
          note: 'Minor scratch noted on rear bumper at pickup',
        ),
      ),
      notes: '',
    ),
    Booking(
      id: 'DD-KL-20260529-0044',
      status: BookingStatus.assigned,
      customer: BookingParty(
        name: 'Faisal Rahman',
        phone: '+91 97460 18822',
      ),
      vehicle: Vehicle(
        make: 'Honda',
        model: 'City',
        type: 'Sedan',
        plate: 'KL-04-N-5512',
      ),
      pickup: RoutePoint(
        address: 'Sea View Ward, Beach Rd, Alappuzha 688012',
        time: '2:00 PM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '4:00 PM',
        sameAsPickup: true,
      ),
      shopId: 's1',
      driverId: 'd2',
      services: [
        BookingService(name: 'Exterior Wash', price: 320, minutes: 35),
        BookingService(name: 'Wax Polish', price: 350, minutes: 30),
      ],
      total: 670,
      payment: PaymentStatus.pending,
      createdAt: '1:12 PM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 1:12 PM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.assigned,
          at: '29 May, 1:20 PM',
          by: 'Vishnu (co-founder)',
        ),
      ],
      damage: DamageReport(),
      notes: 'Cash on delivery — collect ₹670.',
    ),
    Booking(
      id: 'DD-KL-20260529-0041',
      status: BookingStatus.going,
      customer: BookingParty(
        name: 'Lakshmi Pillai',
        phone: '+91 90370 64531',
      ),
      vehicle: Vehicle(
        make: 'Maruti',
        model: 'Baleno',
        type: 'Hatchback',
        plate: 'KL-04-P-3344',
      ),
      pickup: RoutePoint(
        address: 'Pazhaveedu, NH66 Service Rd, Alappuzha 688009',
        time: '12:30 PM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '2:30 PM',
        sameAsPickup: true,
      ),
      shopId: 's2',
      driverId: 'd1',
      services: [
        BookingService(name: 'Exterior Wash', price: 250, minutes: 30),
      ],
      total: 250,
      payment: PaymentStatus.paid,
      createdAt: '11:40 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 11:40 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.assigned,
          at: '29 May, 11:52 AM',
          by: 'Anand (founder)',
        ),
        TimelineEntry(
          status: BookingStatus.going,
          at: '29 May, 12:10 PM',
          by: 'Anand',
        ),
      ],
      damage: DamageReport(),
      notes: '',
    ),
    Booking(
      id: 'DD-KL-20260529-0043',
      status: BookingStatus.completed,
      customer: BookingParty(
        name: 'Deepak Nair',
        phone: '+91 94950 27718',
      ),
      vehicle: Vehicle(
        make: 'Tata',
        model: 'Nexon',
        type: 'Compact SUV',
        plate: 'KL-04-R-6677',
      ),
      pickup: RoutePoint(
        address: 'Iron Bridge North, Alappuzha 688001',
        time: '8:00 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '10:15 AM',
        sameAsPickup: true,
      ),
      shopId: 's5',
      driverId: 'd1',
      services: [
        BookingService(name: 'Exterior Wash', price: 350, minutes: 35),
      ],
      total: 350,
      payment: PaymentStatus.paid,
      createdAt: '7:30 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 7:30 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.completed,
          at: '29 May, 10:12 AM',
          by: 'Anand',
        ),
      ],
      damage: DamageReport(
        pickup: DamageCheck(
          checked: true,
          issues: false,
          note: 'Clean',
        ),
        drop: DamageCheck(
          checked: true,
          issues: false,
          note: 'Returned clean',
        ),
      ),
      notes: '',
    ),
    Booking(
      id: 'DD-KL-20260529-0040',
      status: BookingStatus.cancelled,
      customer: BookingParty(
        name: 'Mohammed Ashraf',
        phone: '+91 98951 40023',
      ),
      vehicle: Vehicle(
        make: 'Toyota',
        model: 'Innova',
        type: 'SUV',
        plate: 'KL-04-C-1100',
      ),
      pickup: RoutePoint(
        address: 'Kalarcode, Alappuzha 688003',
        time: '9:30 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '12:00 PM',
        sameAsPickup: true,
      ),
      shopId: 's1',
      driverId: null,
      services: [
        BookingService(name: 'Full Detail', price: 1100, minutes: 100),
      ],
      total: 1100,
      payment: PaymentStatus.refunded,
      createdAt: '8:05 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 8:05 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.cancelled,
          at: '29 May, 8:22 AM',
          by: 'Customer app',
        ),
      ],
      damage: DamageReport(),
      notes: 'Cancelled by customer before assignment — 100% refund issued.',
    ),
    Booking(
      id: 'DD-KL-20260529-0039',
      status: BookingStatus.completed,
      customer: BookingParty(
        name: 'Reshma S',
        phone: '+91 90480 55310',
      ),
      vehicle: Vehicle(
        make: 'Hyundai',
        model: 'Verna',
        type: 'Sedan',
        plate: 'KL-04-V-4321',
      ),
      pickup: RoutePoint(
        address: 'Mullackal, Convent Square, Alappuzha 688011',
        time: '7:15 AM',
      ),
      drop: RoutePoint(
        address: 'Same as pickup',
        time: '9:30 AM',
        sameAsPickup: true,
      ),
      shopId: 's3',
      driverId: 'd2',
      services: [
        BookingService(name: 'Exterior Wash', price: 320, minutes: 35),
        BookingService(name: 'Interior Vacuum', price: 180, minutes: 25),
      ],
      total: 500,
      payment: PaymentStatus.paid,
      createdAt: '6:50 AM',
      timeline: [
        TimelineEntry(
          status: BookingStatus.created,
          at: '29 May, 6:50 AM',
          by: 'Customer app',
        ),
        TimelineEntry(
          status: BookingStatus.completed,
          at: '29 May, 9:28 AM',
          by: 'Vishnu',
        ),
      ],
      damage: DamageReport(
        pickup: DamageCheck(
          checked: true,
          issues: false,
          note: 'Clean',
        ),
        drop: DamageCheck(
          checked: true,
          issues: false,
          note: 'Clean',
        ),
      ),
      notes: '',
    ),
  ];
}
