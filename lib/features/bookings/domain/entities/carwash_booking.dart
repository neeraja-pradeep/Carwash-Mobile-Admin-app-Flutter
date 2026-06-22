/// A carwash booking from the API list (BookingListSerializer).
/// This is a simplified version used for the booking list, separate from the
/// detailed Booking entity used in the detail screen.
class CarwashBooking {
  const CarwashBooking({
    required this.id,
    required this.reference,
    this.startSlotTime,
    this.appointmentDate,
    this.status,
    this.washingStatus,
    this.customerName,
    this.vehicleLabel,
    this.pickupAddress,
    this.shopName,
    this.shopArea,
    this.amount,
    this.paymentStatus,
    this.isPaid,
    this.assigneeName,
  });

  final int id;
  final String reference;
  final String? startSlotTime;
  final String? appointmentDate;
  final String? status;
  final String? washingStatus;
  final String? customerName;
  final String? vehicleLabel;
  final String? pickupAddress;
  final String? shopName;
  final String? shopArea;
  final String? amount;
  final String? paymentStatus;
  final bool? isPaid;
  final String? assigneeName;
}
