sealed class CarwashSummaryState {
  const CarwashSummaryState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(CarwashSummarySuccess) success,
    required T Function(String) error,
  }) {
    return switch (this) {
      CarwashSummaryInitial() => initial(),
      CarwashSummaryLoading() => loading(),
      CarwashSummarySuccess s => success(s),
      CarwashSummaryError e => error(e.message),
    };
  }
}

class CarwashSummaryInitial extends CarwashSummaryState {
  const CarwashSummaryInitial();
}

class CarwashSummaryLoading extends CarwashSummaryState {
  const CarwashSummaryLoading();
}

class CarwashSummarySuccess extends CarwashSummaryState {
  final String baseFare;
  final String total;
  final String balanceDue;
  final bool nothingToCollect;
  final bool isPaid;
  final String status;
  final String washingStatus;

  const CarwashSummarySuccess({
    required this.baseFare,
    required this.total,
    required this.balanceDue,
    required this.nothingToCollect,
    required this.isPaid,
    required this.status,
    required this.washingStatus,
  });
}

class CarwashSummaryError extends CarwashSummaryState {
  final String message;

  const CarwashSummaryError({required this.message});
}
