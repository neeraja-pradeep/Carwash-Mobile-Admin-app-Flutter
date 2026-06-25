import '../entities/carwash_booking.dart';
import '../../infrastructure/models/booking_detail_response_model.dart';
import '../../infrastructure/models/refund_response_model.dart';
import '../../infrastructure/models/manual_booking_models.dart';

/// Contract for reading car-wash bookings. Pure abstract — no implementation.
abstract class BookingsRepository {
  /// All bookings with optional filters, search, and pagination.
  Future<List<CarwashBooking>> fetchBookings({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? dateRange,
    String? timeOfDay,
    List<String>? statusChips,
    List<String>? shops,
    String? assignment,
    String? sort,
  });

  /// Get full booking detail
  Future<BookingDetailResponse> getBookingDetail(int id);

  /// Get assignable drivers for a booking
  Future<AssignableDriversResponse> getAssignableDrivers(int id);

  /// Assign a driver to a booking
  Future<void> assignDriver(int bookingId, int driverId);

  /// Assign the current user to a booking
  Future<void> assignMe(int bookingId);

  /// Update booking washing status
  Future<void> updateWashingStatus(int bookingId, String washingStatus);

  /// Get damage check report
  Future<Map<String, dynamic>> getDamageCheck(int bookingId);

  /// Save damage check report
  Future<void> saveDamageCheck(
    int bookingId, {
    required String stage,
    required bool checked,
    required String issuesFound,
    List<String>? damageTypes,
    List<String>? panels,
    String? notes,
  });

  /// Cancel a booking with optional reason
  Future<void> cancelBooking(int bookingId, {String? reason});

  /// Refund a booking with optional reason
  Future<void> refundBooking(int bookingId, {String? reason});

  /// Get refund summary for a carwash booking
  Future<RefundSummaryResponse> getRefundSummary(int bookingId);

  /// Create a new refund for a carwash booking
  Future<RefundResponse> createRefund(
    int bookingId, {
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  });

  // ── New Booking (manual carwash) ──────────────────────────────────────────

  /// Create a manual (phone-in) carwash booking. Returns the full created
  /// booking (status=confirmed, payment_mode=offline).
  Future<BookingDetailResponse> createManualBooking({
    required int customerId,
    required int car,
    required int shopId,
    required int serviceId,
    required String vehicleType,
    required String appointmentDate,
    required int startSlot,
    String? pickupAddressText,
    int? addressId,
    bool sameAsPickup,
    int? dropAddress,
    String? couponCode,
    String paymentStatus,
  });

  /// Resolve available slots for a shop/date (maps a time to `start_slot`).
  Future<List<SlotOption>> getAvailableSlots({
    required int shopId,
    required String date,
    String? vehicleType,
  });

  /// Preview the discount for a coupon code against an order amount.
  Future<CouponPreview> validateCoupon({
    required String code,
    required int orderAmount,
  });

  /// Create a vehicle for a customer and return the created `Cars` id.
  Future<CreatedVehicle> createVehicle({
    required int userId,
    required String brandModel,
    required String registration,
    String? carType,
  });
}
