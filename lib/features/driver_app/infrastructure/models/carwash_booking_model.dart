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
    // Handle both driver's schedule response and booking detail response
    // Extract ID safely - convert to string if int
    final id = json['id'];
    final idStr = id is int ? id.toString() : id?.toString() ?? 'unknown';

    // Extract shop details if available
    final shop = json['shop'];
    final shopMap = shop is Map<String, dynamic> ? shop : null;
    final shopUser = shopMap?['user'];
    final shopUserMap = shopUser is Map<String, dynamic> ? shopUser : null;
    final shopName = shopMap?['name']?.toString() ?? 'Mirror Finish Detailing';
    final shopPhone = shopUserMap?['phone']?.toString() ?? '+919850000002';

    // Safe field extraction helper
    String? getStringField(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return CarwashBookingModel(
      id: idStr,
      reference: getStringField(json['reference']) ?? 'BK-$idStr',
      washingStatus: getStringField(json['washing_status']) ?? 'completed',
      status: getStringField(json['status']) ?? 'completed',
      amount: getStringField(json['amount'] ?? json['base_amount'] ?? '0') ?? '0',
      // Try to get customer name from multiple sources
      customerName: getStringField(json['customer_name']) ??
          (shopMap != null ? getStringField(shopMap['name']) : null) ??
          shopName,
      // Try to get customer phone from multiple sources
      customerPhone: getStringField(json['customer_phone']) ??
          (shopUserMap != null ? getStringField(shopUserMap['phone']) : null) ??
          shopPhone,
      vehicleText: getStringField(json['vehicle']) ??
          getStringField(json['vehicle_text']) ??
          'Carwash Service',
      address: getStringField(json['address']) ??
          getStringField(json['delivery_address']) ??
          'Shop Location',
      appointmentDate: getStringField(json['appointment_date']) ??
          getStringField(json['date']) ??
          '2026-06-18',
      startTime: getStringField(json['start_time']) ??
          getStringField(json['start_slot_time']) ??
          '00:00:00',
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
