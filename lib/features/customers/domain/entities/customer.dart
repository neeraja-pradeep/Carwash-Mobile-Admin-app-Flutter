import '../../../../core/status/booking_status.dart';

/// A saved customer address (owned by the customer app, read-only here).
class SavedAddress {
  const SavedAddress({
    required this.label,
    required this.text,
    required this.isDefault,
  });

  final String label;
  final String text;
  final bool isDefault;
}

/// A vehicle in a customer's garage (read-only here).
class GarageVehicle {
  const GarageVehicle({
    required this.make,
    required this.model,
    required this.type,
    required this.plate,
    required this.isDefault,
    required this.bookings,
    this.carId,
  });

  /// The backing `Cars` id from the API (used when booking on the customer's
  /// behalf). `null` for locally-sourced / mock vehicles.
  final int? carId;
  final String make;
  final String model;
  final String type;
  final String plate;
  final bool isDefault;
  final int bookings;

  String get title => '$make $model';
}

/// A lightweight past-booking row shown in a customer's History tab.
class CustomerBookingRef {
  const CustomerBookingRef({
    required this.id,
    required this.date,
    required this.shop,
    required this.status,
    required this.amount,
  });

  final String id;
  final String date;
  final String shop;
  final BookingStatus status;
  final int amount;
}

/// One page of a customer's booking history (server-paginated).
class CustomerHistoryPage {
  const CustomerHistoryPage({
    required this.rows,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  final List<CustomerBookingRef> rows;
  final int count;
  final int page;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;
}

/// A customer directory entry.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.joined,
    required this.blocked,
    required this.blockedReason,
    required this.notes,
    required this.bookings,
    required this.spend,
    required this.lastBooking,
    required this.accountAge,
    required this.addresses,
    required this.vehicles,
    required this.history,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String joined;
  final bool blocked;
  final String blockedReason;
  final String notes;
  final int bookings;
  final int spend;
  final String lastBooking;
  final String accountAge;
  final List<SavedAddress> addresses;
  final List<GarageVehicle> vehicles;
  final List<CustomerBookingRef> history;
}
