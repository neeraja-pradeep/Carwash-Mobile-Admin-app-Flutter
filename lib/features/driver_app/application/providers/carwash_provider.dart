import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/carwash_booking.dart';
import '../../domain/repositories/carwash_repository.dart';
import '../../infrastructure/repositories/carwash_repository_impl.dart';
import '../states/carwash_state.dart';

final carwashRepositoryProvider = Provider<CarwashRepository>((ref) {
  return CarwashRepositoryImpl();
});

final carwashStateProvider = StateNotifierProvider.family<
    CarwashNotifier,
    CarwashState,
    String>((ref, bookingId) {
  final repository = ref.watch(carwashRepositoryProvider);
  return CarwashNotifier(repository, bookingId);
});

class CarwashNotifier extends StateNotifier<CarwashState> {
  final CarwashRepository _repository;
  final String _bookingId;

  CarwashNotifier(this._repository, this._bookingId)
      : super(const CarwashInitial());

  /// Load carwash booking from API
  Future<void> loadBooking() async {
    state = const CarwashLoading();
    try {
      final booking = await _repository.getBooking(_bookingId);
      state = CarwashSuccess(booking: booking);
    } catch (e) {
      state = CarwashError(message: e.toString());
    }
  }

  /// Advance washing status to the next step
  Future<void> advanceWashingStatus(String newStatus) async {
    if (state is! CarwashSuccess) return;
    final success = state as CarwashSuccess;
    state = CarwashSuccess(booking: success.booking, isUpdating: true);

    try {
      final updatedBooking =
          await _repository.advanceWashingStatus(_bookingId, newStatus);
      // The PATCH replies with only `id` / `washing_status` / `updated_at`, so
      // its parsed booking has placeholder values for everything else. Take
      // just the advanced status and keep the loaded booking underneath —
      // swapping the whole object in blanked the fare, customer and vehicle.
      state = CarwashSuccess(
        booking: success.booking.copyWith(
          washingStatus: updatedBooking.washingStatus,
        ),
      );
    } catch (e) {
      state = CarwashSuccess(booking: success.booking);
      rethrow;
    }
  }

  /// Load carwash summary for completed bookings
  Future<Map<String, dynamic>> loadSummary() async {
    try {
      return await _repository.getCarwashSummary(_bookingId);
    } catch (e) {
      rethrow;
    }
  }

  /// Load summary first for completed jobs, fallback to booking for in-progress
  Future<void> loadBookingWithSummaryFallback() async {
    state = const CarwashLoading();
    try {
      // Try summary endpoint first (for completed jobs)
      try {
        final summary = await _repository.getCarwashSummary(_bookingId);
        // Summary loaded - also load booking to get customer details
        try {
          final booking = await _repository.getBooking(_bookingId);
          // Merge: use booking data for customer info, keep summary for price data
          state = CarwashSuccess(booking: booking);
          return;
        } catch (e) {
          debugPrint('Could not load booking details for completed job: $e');
          // Create minimal booking from summary if booking fails
          final booking = CarwashBooking(
            id: _bookingId,
            reference: 'BK-$_bookingId',
            washingStatus: summary['washing_status'] ?? 'completed',
            status: summary['status'] ?? 'completed',
            amount: (summary['base_fare'] ?? '0').toString(),
            customerName: 'Customer',
            customerPhone: '',
            vehicleText: 'Vehicle',
            address: '',
            appointmentDate: '',
            startTime: '',
          );
          state = CarwashSuccess(booking: booking);
          return;
        }
      } catch (e) {
        debugPrint('Summary endpoint failed, trying booking endpoint: $e');
      }

      // Fallback to booking endpoint (for in-progress jobs)
      final booking = await _repository.getBooking(_bookingId);
      state = CarwashSuccess(booking: booking);
    } catch (e) {
      state = CarwashError(message: e.toString());
      rethrow;
    }
  }
}
