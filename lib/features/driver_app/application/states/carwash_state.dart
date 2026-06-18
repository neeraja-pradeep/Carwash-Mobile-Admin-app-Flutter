import '../../domain/entities/carwash_booking.dart';

sealed class CarwashState {
  const CarwashState();
}

class CarwashInitial extends CarwashState {
  const CarwashInitial();
}

class CarwashLoading extends CarwashState {
  const CarwashLoading();
}

class CarwashSuccess extends CarwashState {
  final CarwashBooking booking;
  final bool isUpdating;

  const CarwashSuccess({
    required this.booking,
    this.isUpdating = false,
  });
}

class CarwashError extends CarwashState {
  final String message;

  const CarwashError({required this.message});
}
