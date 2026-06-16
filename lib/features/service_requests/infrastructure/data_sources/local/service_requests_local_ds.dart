import '../../../../../app/config/constants.dart';
import '../../../../../features/drivers/domain/entities/field_driver.dart';
import '../../../domain/entities/service_request.dart';
import '../../../../../core/status/service_request_status.dart';

/// Static sample service requests (Alappuzha demo set, from `data.jsx`
/// SERVICE_REQUESTS lines 729–812 — EXACT values preserved).
///
/// This is the ONLY place service-request data lives today. In the API phase
/// a remote data source + Hive cache plug in behind the same repository
/// contract; the UI and providers stay unchanged.
class ServiceRequestsLocalDs {
  const ServiceRequestsLocalDs();

  Future<List<ServiceRequest>> fetchServiceRequests() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _requests;
  }

  static final List<ServiceRequest> _requests = [
    ServiceRequest(
      id: 'SR-DR-20260529-014',
      kind: SrKind.driver,
      status: ServiceRequestStatus.created,
      customer: const SrCustomer(
        name: 'Vivek Anand',
        phone: '+91 94470 90012',
      ),
      vehicle: const SrVehicle(
        make: 'Toyota',
        model: 'Fortuner',
        type: 'SUV',
        plate: 'KL-04-X-4412',
      ),
      when: '30 May, 7:00 AM',
      duration: 'Full day (8 hrs)',
      location: 'Mullackal, Alappuzha 688011',
      assigneeId: null,
      fee: null,
      createdAt: '29 May, 6:40 PM',
      reason: 'Round Trip',
      otp: '4821',
      note: 'Outstation trip to Kochi airport and back. Needs experienced highway driver.',
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '29 May, 6:40 PM',
          by: 'Customer app',
        ),
      ],
    ),

    ServiceRequest(
      id: 'SR-IN-20260529-013',
      kind: SrKind.inspection,
      status: ServiceRequestStatus.contacted,
      customer: const SrCustomer(
        name: 'Meera Jacob',
        phone: '+91 98951 22310',
      ),
      vehicle: const SrVehicle(
        make: 'Honda',
        model: 'City (2019, used)',
        type: 'Sedan',
        plate: 'Pre-purchase',
      ),
      when: '30 May, 11:00 AM',
      duration: '~1 hr',
      location: 'Thathampally, near Beach Rd, Alappuzha',
      assigneeId: null,
      fee: 800,
      createdAt: '29 May, 4:15 PM',
      otp: '7390',
      note: 'Pre-purchase inspection before buying a used City. Seller available 11am–1pm.',
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '29 May, 4:15 PM',
          by: 'Customer app',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.contacted,
          at: '29 May, 4:40 PM',
          by: 'Anand',
        ),
      ],
    ),

    ServiceRequest(
      id: 'SR-DR-20260529-012',
      kind: SrKind.driver,
      status: ServiceRequestStatus.inProgress,
      customer: const SrCustomer(
        name: 'Sandra Pius',
        phone: '+91 90370 18820',
      ),
      vehicle: const SrVehicle(
        make: 'Maruti',
        model: 'Ertiga',
        type: 'SUV',
        plate: 'KL-04-Q-7781',
      ),
      when: '29 May, 5:00 PM',
      duration: '4 hrs',
      location: 'Komala Rd, Alappuzha 688001',
      assigneeId: 'fd1',
      fee: 600,
      createdAt: '29 May, 2:10 PM',
      reason: 'Hospital Assistance',
      otp: '5512',
      startLoc: 'Komala Rd, near Boat Jetty',
      live: const LiveLocation(
        label: 'NH66, near Kalarcode',
        moving: true,
        lastUpdate: 'just now',
      ),
      note: 'City driving for a family event. Return by 9pm.',
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '29 May, 2:10 PM',
          by: 'Customer app',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.contacted,
          at: '29 May, 2:25 PM',
          by: 'Vishnu',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.assigned,
          at: '29 May, 2:40 PM',
          by: 'Vishnu',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.inProgress,
          at: '29 May, 5:08 PM',
          by: 'Manoj Kumar',
          location: 'Komala Rd, near Boat Jetty',
        ),
      ],
    ),

    ServiceRequest(
      id: 'SR-IN-20260529-011',
      kind: SrKind.inspection,
      status: ServiceRequestStatus.inProgress,
      customer: const SrCustomer(
        name: 'Tom Kurian',
        phone: '+91 95440 71129',
      ),
      vehicle: const SrVehicle(
        make: 'Hyundai',
        model: 'Creta (2020, used)',
        type: 'Compact SUV',
        plate: 'KL-04-Z-3301',
      ),
      when: '29 May, 1:00 PM',
      duration: '~1 hr',
      location: 'Vazhicherry, Alappuzha 688012',
      assigneeId: 'in1',
      fee: 800,
      createdAt: '29 May, 10:05 AM',
      otp: '6204',
      startLoc: 'Vazhicherry Ward, CCNB Rd',
      live: const LiveLocation(
        label: 'Vazhicherry Ward, CCNB Rd (at vehicle)',
        moving: false,
        lastUpdate: '4 min ago',
      ),
      note: 'Pre-sale inspection report needed for resale listing.',
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '29 May, 10:05 AM',
          by: 'Customer app',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.contacted,
          at: '29 May, 10:20 AM',
          by: 'Anand',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.assigned,
          at: '29 May, 10:35 AM',
          by: 'Anand',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.inProgress,
          at: '29 May, 1:05 PM',
          by: 'Ravi Menon',
        ),
      ],
    ),

    ServiceRequest(
      id: 'SR-DR-20260528-010',
      kind: SrKind.driver,
      status: ServiceRequestStatus.completed,
      customer: const SrCustomer(
        name: 'Asha Nair',
        phone: '+91 94950 60074',
      ),
      vehicle: const SrVehicle(
        make: 'Kia',
        model: 'Carnival',
        type: 'SUV',
        plate: 'KL-04-W-9002',
      ),
      when: '28 May, 6:00 AM',
      duration: 'Full day (10 hrs)',
      location: 'Pazhaveedu, Alappuzha 688009',
      assigneeId: 'd1',
      fee: 1200,
      createdAt: '27 May, 8:30 PM',
      reason: 'Round Trip',
      otp: '3088',
      startLoc: 'Pazhaveedu, NH66 Service Rd',
      endLoc: 'Pazhaveedu, NH66 Service Rd',
      note: 'Wedding day chauffeur. Completed without issues.',
      summary: const SrSummary(
        plannedHours: 10,
        actualHours: 12,
        extraKm: 0,
        baseFee: 1200,
        extraCharge: 240,
        extraReason: '2 hrs over planned duration (₹120/hr)',
        total: 1440,
        paid: true,
      ),
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '27 May, 8:30 PM',
          by: 'Customer app',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.contacted,
          at: '27 May, 8:50 PM',
          by: 'Anand',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.assigned,
          at: '27 May, 9:10 PM',
          by: 'Anand',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.inProgress,
          at: '28 May, 6:05 AM',
          by: 'Anand',
          location: 'Pazhaveedu, NH66 Service Rd',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.completed,
          at: '28 May, 6:18 PM',
          by: 'Anand',
          location: 'Pazhaveedu, NH66 Service Rd',
        ),
      ],
    ),

    ServiceRequest(
      id: 'SR-IN-20260528-009',
      kind: SrKind.inspection,
      status: ServiceRequestStatus.cancelled,
      customer: const SrCustomer(
        name: 'Rahul Dev',
        phone: '+91 97460 55218',
      ),
      vehicle: const SrVehicle(
        make: 'Tata',
        model: 'Harrier (used)',
        type: 'SUV',
        plate: 'Pre-purchase',
      ),
      when: '28 May, 3:00 PM',
      duration: '~1 hr',
      location: 'Iron Bridge North, Alappuzha 688001',
      assigneeId: null,
      fee: 800,
      createdAt: '28 May, 9:10 AM',
      otp: '',
      note: 'Customer cancelled — deal fell through before inspection.',
      timeline: const [
        SrTimelineEntry(
          status: ServiceRequestStatus.created,
          at: '28 May, 9:10 AM',
          by: 'Customer app',
        ),
        SrTimelineEntry(
          status: ServiceRequestStatus.cancelled,
          at: '28 May, 11:30 AM',
          by: 'Customer app',
        ),
      ],
    ),
  ];
}
