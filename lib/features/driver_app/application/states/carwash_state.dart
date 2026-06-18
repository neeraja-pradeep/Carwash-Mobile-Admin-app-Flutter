import '../../domain/entities/carwash_booking.dart';

sealed class CarwashState {
  const CarwashState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(CarwashSuccess) success,
    required T Function(CarwashError) error,
  }) {
    return switch (this) {
      CarwashInitial() => initial(),
      CarwashLoading() => loading(),
      CarwashSuccess s => success(s),
      CarwashError e => error(e),
    };
  }
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
