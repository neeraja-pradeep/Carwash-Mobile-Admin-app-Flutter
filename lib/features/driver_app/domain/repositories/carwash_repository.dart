import '../entities/carwash_booking.dart';

abstract class CarwashRepository {
  Future<CarwashBooking> getBooking(String bookingId);
  Future<CarwashBooking> advanceWashingStatus(String bookingId, String washingStatus);
  Future<Map<String, dynamic>> getCarwashSummary(String bookingId);
}
