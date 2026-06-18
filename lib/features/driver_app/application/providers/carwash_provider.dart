import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final updatedBooking = await _repository.advanceWashingStatus(_bookingId, newStatus);
      state = CarwashSuccess(booking: updatedBooking);
    } catch (e) {
      state = CarwashSuccess(booking: success.booking);
      rethrow;
    }
  }
}
