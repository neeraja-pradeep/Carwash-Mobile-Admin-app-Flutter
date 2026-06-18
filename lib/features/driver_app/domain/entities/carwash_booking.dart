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
  });
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

  static int? indexOfValue(String value) {
    try {
      return steps.indexWhere((s) => s.value == value);
    } catch (e) {
      return null;
    }
  }

  static String? nextStatus(String currentValue) {
    final currentIndex = indexOfValue(currentValue);
    if (currentIndex != null && currentIndex < steps.length - 1) {
      return steps[currentIndex + 1].value;
    }
    return null;
  }
}
