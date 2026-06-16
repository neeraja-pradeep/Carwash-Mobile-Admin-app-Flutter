import '../../../../../app/config/constants.dart';
import '../../../../../core/status/booking_status.dart';
import '../../../domain/entities/customer.dart';

/// Static sample customers (Alappuzha demo set, from `data.jsx` CUSTOMERS).
///
/// This is the ONLY place customer data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class CustomersLocalDs {
  const CustomersLocalDs();

  Future<List<Customer>> fetchCustomers() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _customers;
  }

  Future<Customer?> fetchCustomerById(String id) async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<Customer> _customers = [
    Customer(
      id: 'c1',
      name: 'Ramesh Kurup',
      phone: '+91 94470 56789',
      email: 'ramesh.kurup@gmail.com',
      joined: '12-Sep-2025',
      blocked: false,
      blockedReason: '',
      notes: 'Prefers morning slots. Gate code #4421.',
      bookings: 24,
      spend: 8450,
      lastBooking: '29-May-2026',
      accountAge: '8 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Mullackal Junction, near Temple Rd, Alappuzha 688011',
          isDefault: true,
        ),
        SavedAddress(
          label: 'Office',
          text: 'CCSB Rd, Vazhicherry, Alappuzha 688012',
          isDefault: false,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Maruti',
          model: 'Swift Dzire',
          type: 'Sedan',
          plate: 'KL-04-K-7788',
          isDefault: true,
          bookings: 19,
        ),
        GarageVehicle(
          make: 'Honda',
          model: 'Activa',
          type: 'Hatchback',
          plate: 'KL-04-G-2231',
          isDefault: false,
          bookings: 5,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0042',
          date: '29-May',
          shop: 'SparkleWash Mullackal',
          status: BookingStatus.washing,
          amount: 500,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260521-0033',
          date: '21-May',
          shop: 'SparkleWash Mullackal',
          status: BookingStatus.completed,
          amount: 650,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260514-0028',
          date: '14-May',
          shop: 'GleamPro Vazhicherry',
          status: BookingStatus.completed,
          amount: 320,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260502-0011',
          date: '02-May',
          shop: 'SparkleWash Mullackal',
          status: BookingStatus.completed,
          amount: 900,
        ),
      ],
    ),
    Customer(
      id: 'c2',
      name: 'Priya Menon',
      phone: '+91 98470 11234',
      email: 'priya.menon@outlook.com',
      joined: '03-Jan-2026',
      blocked: false,
      blockedReason: '',
      notes: '',
      bookings: 7,
      spend: 1980,
      lastBooking: '29-May-2026',
      accountAge: '5 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Thathampally Beach Rd, near Lighthouse, Alappuzha 688013',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Hyundai',
          model: 'i20',
          type: 'Hatchback',
          plate: 'KL-04-AB-1234',
          isDefault: true,
          bookings: 7,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0048',
          date: '29-May',
          shop: 'AquaShine Thathampally',
          status: BookingStatus.created,
          amount: 250,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260512-0009',
          date: '12-May',
          shop: 'AquaShine Thathampally',
          status: BookingStatus.completed,
          amount: 250,
        ),
      ],
    ),
    Customer(
      id: 'c3',
      name: 'Anitha Thomas',
      phone: '+91 95440 33871',
      email: '',
      joined: '21-Nov-2025',
      blocked: false,
      blockedReason: '',
      notes: 'Owns 2 vehicles, books fortnightly.',
      bookings: 15,
      spend: 11200,
      lastBooking: '29-May-2026',
      accountAge: '6 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Vazhicherry Ward, CCNB Rd, Alappuzha 688012',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Kia',
          model: 'Seltos',
          type: 'Compact SUV',
          plate: 'KL-04-M-2201',
          isDefault: true,
          bookings: 11,
        ),
        GarageVehicle(
          make: 'Toyota',
          model: 'Glanza',
          type: 'Hatchback',
          plate: 'KL-04-H-8890',
          isDefault: false,
          bookings: 4,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0046',
          date: '29-May',
          shop: 'GleamPro Vazhicherry',
          status: BookingStatus.done,
          amount: 900,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260515-0021',
          date: '15-May',
          shop: 'GleamPro Vazhicherry',
          status: BookingStatus.completed,
          amount: 950,
        ),
      ],
    ),
    Customer(
      id: 'c4',
      name: 'Sajan Varghese',
      phone: '+91 99950 71240',
      email: 'sajan.v@gmail.com',
      joined: '18-Feb-2026',
      blocked: false,
      blockedReason: '',
      notes: '',
      bookings: 5,
      spend: 3100,
      lastBooking: '29-May-2026',
      accountAge: '3 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Komala Rd, near Boat Jetty, Alappuzha 688001',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Mahindra',
          model: 'Thar',
          type: 'SUV',
          plate: 'KL-04-T-9090',
          isDefault: true,
          bookings: 5,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0045',
          date: '29-May',
          shop: 'BlueWave Komala Rd',
          status: BookingStatus.returning,
          amount: 600,
        ),
      ],
    ),
    Customer(
      id: 'c5',
      name: 'Deepak Nair',
      phone: '+91 94950 27718',
      email: 'deepak.nair@yahoo.com',
      joined: '30-Oct-2025',
      blocked: false,
      blockedReason: '',
      notes: 'Regular — never misses a wash.',
      bookings: 31,
      spend: 9870,
      lastBooking: '29-May-2026',
      accountAge: '7 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Iron Bridge North, Alappuzha 688001',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Tata',
          model: 'Nexon',
          type: 'Compact SUV',
          plate: 'KL-04-R-6677',
          isDefault: true,
          bookings: 31,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0043',
          date: '29-May',
          shop: 'ShineHub Iron Bridge',
          status: BookingStatus.completed,
          amount: 350,
        ),
        CustomerBookingRef(
          id: 'DD-KL-20260522-0040',
          date: '22-May',
          shop: 'ShineHub Iron Bridge',
          status: BookingStatus.completed,
          amount: 350,
        ),
      ],
    ),
    Customer(
      id: 'c6',
      name: 'Lakshmi Pillai',
      phone: '+91 90370 64531',
      email: '',
      joined: '11-Mar-2026',
      blocked: false,
      blockedReason: '',
      notes: '',
      bookings: 4,
      spend: 1000,
      lastBooking: '29-May-2026',
      accountAge: '2 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Pazhaveedu, NH66 Service Rd, Alappuzha 688009',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Maruti',
          model: 'Baleno',
          type: 'Hatchback',
          plate: 'KL-04-P-3344',
          isDefault: true,
          bookings: 4,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0041',
          date: '29-May',
          shop: 'AquaShine Thathampally',
          status: BookingStatus.going,
          amount: 250,
        ),
      ],
    ),
    Customer(
      id: 'c7',
      name: 'Mohammed Ashraf',
      phone: '+91 98951 40023',
      email: 'm.ashraf@gmail.com',
      joined: '24-Apr-2026',
      blocked: true,
      blockedReason: 'Fake bookings',
      notes: 'Blocked 29-May after 3 no-show cancellations in a week.',
      bookings: 3,
      spend: 0,
      lastBooking: '29-May-2026',
      accountAge: '1 month',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Kalarcode, Alappuzha 688003',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Toyota',
          model: 'Innova',
          type: 'SUV',
          plate: 'KL-04-C-1100',
          isDefault: true,
          bookings: 3,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0040',
          date: '29-May',
          shop: 'SparkleWash Mullackal',
          status: BookingStatus.cancelled,
          amount: 1100,
        ),
      ],
    ),
    Customer(
      id: 'c8',
      name: 'Reshma S',
      phone: '+91 90480 55310',
      email: 'reshma.s@gmail.com',
      joined: '07-Dec-2025',
      blocked: false,
      blockedReason: '',
      notes: '',
      bookings: 12,
      spend: 5640,
      lastBooking: '29-May-2026',
      accountAge: '5 months',
      addresses: const [
        SavedAddress(
          label: 'Home',
          text: 'Mullackal, Convent Square, Alappuzha 688011',
          isDefault: true,
        ),
      ],
      vehicles: const [
        GarageVehicle(
          make: 'Hyundai',
          model: 'Verna',
          type: 'Sedan',
          plate: 'KL-04-V-4321',
          isDefault: true,
          bookings: 12,
        ),
      ],
      history: const [
        CustomerBookingRef(
          id: 'DD-KL-20260529-0039',
          date: '29-May',
          shop: 'GleamPro Vazhicherry',
          status: BookingStatus.completed,
          amount: 500,
        ),
      ],
    ),
  ];
}
