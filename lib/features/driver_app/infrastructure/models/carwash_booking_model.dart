import '../../domain/entities/carwash_booking.dart';

class CarwashBookingModel extends CarwashBooking {
  CarwashBookingModel({
    required super.id,
    required super.reference,
    required super.washingStatus,
    required super.status,
    required super.amount,
    required super.customerName,
    required super.customerPhone,
    required super.vehicleText,
    required super.address,
    required super.appointmentDate,
    required super.startTime,
  });

  factory CarwashBookingModel.fromJson(Map<String, dynamic> json) {
    return CarwashBookingModel(
      id: json['id'].toString(),
      reference: json['reference'],
      washingStatus: json['washing_status'],
      status: json['status'],
      amount: json['amount'].toString(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      vehicleText: json['vehicle'],
      address: json['address'],
      appointmentDate: json['appointment_date'],
      startTime: json['start_time'],
    );
  }

  CarwashBooking toEntity() => CarwashBooking(
    id: id,
    reference: reference,
    washingStatus: washingStatus,
    status: status,
    amount: amount,
    customerName: customerName,
    customerPhone: customerPhone,
    vehicleText: vehicleText,
    address: address,
    appointmentDate: appointmentDate,
    startTime: startTime,
  );
}
