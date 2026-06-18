import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../infrastructure/repositories/schedule_repository_impl.dart';
import '../states/carwash_summary_state.dart';

final carwashSummaryRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

final carwashSummaryStateProvider = StateNotifierProvider.family<
    CarwashSummaryNotifier,
    CarwashSummaryState,
    String>((ref, bookingId) {
  final repository = ref.watch(carwashSummaryRepositoryProvider);
  return CarwashSummaryNotifier(repository, bookingId);
});

class CarwashSummaryNotifier extends StateNotifier<CarwashSummaryState> {
  final ScheduleRepository _repository;
  final String _bookingId;

  CarwashSummaryNotifier(this._repository, this._bookingId)
      : super(const CarwashSummaryInitial());

  /// Load carwash job summary
  Future<void> loadSummary() async {
    state = const CarwashSummaryLoading();
    try {
      final summary = await _repository.getCarwashSummary(_bookingId);
      state = CarwashSummarySuccess(
        baseFare: (summary['base_fare'] ?? '0').toString(),
        total: (summary['total'] ?? '0').toString(),
        balanceDue: (summary['balance_due'] ?? '0').toString(),
        nothingToCollect: summary['nothing_to_collect'] ?? true,
        isPaid: summary['is_paid'] ?? false,
        status: summary['status'] ?? 'completed',
        washingStatus: summary['washing_status'] ?? 'completed',
      );
    } catch (e) {
      state = CarwashSummaryError(message: e.toString());
    }
  }
}
