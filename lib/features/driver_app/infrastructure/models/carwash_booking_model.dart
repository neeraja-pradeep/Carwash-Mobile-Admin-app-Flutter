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
    super.latitude,
    super.longitude,
  });

  factory CarwashBookingModel.fromJson(Map<String, dynamic> json) {
    // Handle both driver's schedule response and booking detail response
    // Extract ID safely - convert to string if int
    final id = json['id'];
    final idStr = id is int ? id.toString() : id?.toString() ?? 'unknown';

    // Safe field extraction helper
    String? getStringField(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    // The pickup address and its coordinates both live on the nested
    // `address_detail`; the top-level `address` is only its numeric id. Absent
    // on partial PATCH payloads, where coordinates resolve to 0 and are merged
    // away by CarwashBooking.copyWith.
    double parseCoordinate(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final addressDetail = json['address_detail'];
    final detail =
        addressDetail is Map<String, dynamic> ? addressDetail : const {};

    // `/bookings/{id}/` carries no ready-made address string: `address_detail`
    // holds the parts and the top-level `address` is just its id. Join the
    // parts the way the worker list endpoints pre-join their `pickup_address`,
    // so both routes read the same — "G87P+2G3, Alappuzha, 688006".
    String? joinAddressParts() {
      const keys = ['address_line', 'landmark', 'city', 'state', 'pincode'];
      final joined = keys
          .map((key) => getStringField(detail[key])?.trim() ?? '')
          .where((part) => part.isNotEmpty)
          .join(', ');
      return joined.isEmpty ? null : joined;
    }

    // Absent fields resolve to empty, never to invented data. This parses
    // partial payloads too — `PATCH /bookings/{id}/` answers with only the
    // fields it changed — and stand-in values there were being shown as though
    // the server had sent them: a real shop's name and phone number in place of
    // the customer's, and a status of "completed" for a job still in progress.
    // The remaining `??` chains are alternate key names for the same value
    // across endpoints, not substitutes for missing data.
    return CarwashBookingModel(
      id: idStr,
      reference: getStringField(json['reference']) ?? '',
      washingStatus: getStringField(json['washing_status']) ?? '',
      status: getStringField(json['status']) ?? '',
      amount: getStringField(json['amount'] ?? json['base_amount']) ?? '',
      customerName: getStringField(json['customer_name']) ?? '',
      customerPhone: getStringField(json['customer_phone']) ?? '',
      vehicleText: getStringField(json['vehicle']) ??
          getStringField(json['vehicle_text']) ??
          '',
      // A top-level `address` is the FK id on `/bookings/{id}/` and only ever
      // text on the worker list endpoints, so take it only when it really is a
      // String — stringifying the id rendered "5" as the service location.
      address: getStringField(json['pickup_address']) ??
          joinAddressParts() ??
          (json['address'] is String ? json['address'] as String : null) ??
          (json['delivery_address'] is String
              ? json['delivery_address'] as String
              : null) ??
          '',
      appointmentDate: getStringField(json['appointment_date']) ??
          getStringField(json['date']) ??
          '',
      startTime: getStringField(json['start_time']) ??
          getStringField(json['start_slot_time']) ??
          '',
      latitude: parseCoordinate(detail['latitude']),
      longitude: parseCoordinate(detail['longitude']),
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
    latitude: latitude,
    longitude: longitude,
  );
}
