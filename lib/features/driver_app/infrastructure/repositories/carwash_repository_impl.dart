import '../../domain/entities/carwash_booking.dart';
import '../../domain/repositories/carwash_repository.dart';
import '../data_sources/carwash_api.dart';

class CarwashRepositoryImpl implements CarwashRepository {
  final CarwashApi _api = CarwashApi();

  @override
  Future<CarwashBooking> getBooking(String bookingId) async {
    final model = await _api.getBooking(bookingId);
    return model.toEntity();
  }

  @override
  Future<CarwashBooking> advanceWashingStatus(
    String bookingId,
    String washingStatus,
  ) async {
    final model = await _api.advanceWashingStatus(bookingId, washingStatus);
    return model.toEntity();
  }
}
