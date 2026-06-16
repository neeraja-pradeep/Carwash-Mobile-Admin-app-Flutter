import '../entities/booking.dart';

/// Contract for reading car-wash bookings. Pure abstract — no implementation.
abstract class BookingsRepository {
  /// All bookings (today's demo set).
  Future<List<Booking>> fetchBookings();
}
