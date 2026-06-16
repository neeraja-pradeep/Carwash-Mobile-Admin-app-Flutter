import '../../../../core/status/booking_status.dart';
import '../../../../core/status/payment_status.dart';

/// A car-wash booking and its nested value objects.
///
/// Pure, immutable value object — no fetching/display logic. The static data
/// source constructs these from Dart literals today; the API phase will add a
/// remote source that maps JSON onto the same shapes.
class Booking {
  const Booking({
    required this.id,
    required this.status,
    required this.customer,
    required this.vehicle,
    required this.pickup,
    required this.drop,
    required this.shopId,
    required this.services,
    required this.total,
    required this.payment,
    required this.createdAt,
    required this.timeline,
    required this.damage,
    this.driverId,
    this.notes = '',
  });

  final String id;
  final BookingStatus status;
  final BookingParty customer;
  final Vehicle vehicle;
  final RoutePoint pickup;
  final RoutePoint drop;
  final String shopId;
  final String? driverId;
  final List<BookingService> services;
  final int total;
  final PaymentStatus payment;
  final String createdAt;
  final List<TimelineEntry> timeline;
  final DamageReport damage;
  final String notes;

  int get estimatedMinutes => services.fold(0, (sum, s) => sum + s.minutes);
}

/// A named contact with a tap-to-call phone (customer on a booking).
class BookingParty {
  const BookingParty({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// A vehicle make/model/type and (optional) plate.
class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.type,
    this.plate,
  });

  final String make;
  final String model;
  final String type;
  final String? plate;

  String get title => '$make $model';
}

/// A pickup or drop location with a scheduled time.
class RoutePoint {
  const RoutePoint({
    required this.address,
    required this.time,
    this.sameAsPickup = false,
  });

  final String address;
  final String time;
  final bool sameAsPickup;
}

/// A selected service line on a booking (price snapshotted at booking time).
class BookingService {
  const BookingService({
    required this.name,
    required this.price,
    required this.minutes,
  });

  final String name;
  final int price;
  final int minutes;
}

/// One status transition in the booking timeline.
class TimelineEntry {
  const TimelineEntry({
    required this.status,
    required this.at,
    required this.by,
  });

  final BookingStatus status;
  final String at;
  final String by;
}

/// A single damage-check entry (pickup or drop).
class DamageCheck {
  const DamageCheck({
    required this.checked,
    required this.issues,
    required this.note,
  });

  final bool checked;
  final bool issues;
  final String note;
}

/// Pickup + drop damage checks for a booking.
class DamageReport {
  const DamageReport({this.pickup, this.drop});

  final DamageCheck? pickup;
  final DamageCheck? drop;
}
