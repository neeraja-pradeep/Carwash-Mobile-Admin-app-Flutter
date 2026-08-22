class CarwashBooking {
  final String id;
  final String reference;
  final String washingStatus;
  final String status;
  final String amount;
  final String customerName;
  final String customerPhone;
  final String vehicleText;
  final String address;
  final String appointmentDate;
  final String startTime;

  /// Pickup coordinates, from the booking's `address_detail`. Both are 0 when
  /// the payload carries no location — callers must treat that as "unknown"
  /// rather than as a point off the coast of Africa.
  final double latitude;
  final double longitude;

  bool get hasCoordinates => latitude != 0 || longitude != 0;

  CarwashBooking({
    required this.id,
    required this.reference,
    required this.washingStatus,
    required this.status,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleText,
    required this.address,
    required this.appointmentDate,
    required this.startTime,
    this.latitude = 0,
    this.longitude = 0,
  });

  /// Returns a copy with the given fields replaced.
  ///
  /// Needed because `PATCH /bookings/{id}/` answers with only the fields it
  /// changed (`id`, `washing_status`, `updated_at`). Rebuilding the booking
  /// from that reply alone blanks everything it omits, so callers merge the
  /// changed fields onto the booking they already hold.
  CarwashBooking copyWith({
    String? id,
    String? reference,
    String? washingStatus,
    String? status,
    String? amount,
    String? customerName,
    String? customerPhone,
    String? vehicleText,
    String? address,
    String? appointmentDate,
    String? startTime,
    double? latitude,
    double? longitude,
  }) {
    return CarwashBooking(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      washingStatus: washingStatus ?? this.washingStatus,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleText: vehicleText ?? this.vehicleText,
      address: address ?? this.address,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      startTime: startTime ?? this.startTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class WashingStatusStep {
  final String value;
  final String label;

  WashingStatusStep({required this.value, required this.label});

  static final steps = [
    WashingStatusStep(value: 'confirmed', label: 'Confirmed'),
    WashingStatusStep(value: 'crew_en_route', label: 'Going for pickup'),
    WashingStatusStep(value: 'picked_up', label: 'Car picked up'),
    WashingStatusStep(value: 'dropped_at_shop', label: 'Dropped at shop'),
    WashingStatusStep(value: 'in_progress', label: 'Wash started'),
    WashingStatusStep(value: 'wash_done', label: 'Wash done'),
    WashingStatusStep(value: 'picked_up_from_shop', label: 'Picked up from shop'),
    WashingStatusStep(value: 'returning', label: 'Dropped to customer'),
    WashingStatusStep(value: 'completed', label: 'Completed'),
  ];

  static String labelForValue(String value) {
    try {
      return steps.firstWhere((s) => s.value == value).label;
    } catch (e) {
      return value;
    }
  }

  /// Position of [value] in [steps], or null if it isn't a known step.
  ///
  /// `indexWhere` returns -1 rather than throwing, so the old catch never ran
  /// and -1 escaped as a real index: an unrecognised status made [nextStatus]
  /// offer step 0 ("confirmed"), which would have walked a job backwards.
  static int? indexOfValue(String value) {
    final index = steps.indexWhere((s) => s.value == value);
    return index == -1 ? null : index;
  }

  static String? nextStatus(String currentValue) {
    final currentIndex = indexOfValue(currentValue);
    if (currentIndex != null && currentIndex < steps.length - 1) {
      return steps[currentIndex + 1].value;
    }
    return null;
  }
}
