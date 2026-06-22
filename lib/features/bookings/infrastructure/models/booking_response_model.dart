import '../../../bookings/domain/entities/carwash_booking.dart';

/// Response from bookings list API
class BookingListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<BookingModel> results;

  BookingListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    return BookingListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => BookingModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Booking model from API response (BookingListSerializer)
class BookingModel {
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

  BookingModel({
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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int? ?? 0,
      reference: json['reference'] as String? ?? '',
      startSlotTime: json['start_slot_time'] as String?,
      appointmentDate: json['appointment_date'] as String?,
      status: json['status'] as String?,
      washingStatus: json['washing_status'] as String?,
      customerName: json['customer_name'] as String?,
      vehicleLabel: json['vehicle_label'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      shopName: json['shop_name'] as String?,
      shopArea: json['shop_area'] as String?,
      amount: json['amount']?.toString(),
      paymentStatus: json['payment_status'] as String?,
      isPaid: json['is_paid'] as bool?,
      assigneeName: json['assignee_name'] as String?,
    );
  }

  CarwashBooking toCarwashEntity() {
    return CarwashBooking(
      id: id,
      reference: reference,
      startSlotTime: startSlotTime,
      appointmentDate: appointmentDate,
      status: status,
      washingStatus: washingStatus,
      customerName: customerName,
      vehicleLabel: vehicleLabel,
      pickupAddress: pickupAddress,
      shopName: shopName,
      shopArea: shopArea,
      amount: amount,
      paymentStatus: paymentStatus,
      isPaid: isPaid,
      assigneeName: assigneeName,
    );
  }
}
