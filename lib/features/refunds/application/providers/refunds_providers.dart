import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/refund.dart';
import '../../domain/repositories/refunds_repository.dart';
import '../../infrastructure/data_sources/local/refunds_local_ds.dart';
import '../../infrastructure/repositories/refunds_repository_impl.dart';
import '../states/refunds_filter_state.dart';

/// Local data source provider.
final refundsLocalDsProvider = Provider<RefundsLocalDs>(
  (ref) => const RefundsLocalDs(),
);

/// The refunds repository (domain contract → infrastructure impl).
final refundsRepositoryProvider = Provider<RefundsRepository>(
  (ref) => RefundsRepositoryImpl(ref.watch(refundsLocalDsProvider)),
);

/// All refunds (read). Kept alive so back-navigation is instant.
final refundsProvider = FutureProvider<List<Refund>>(
  (ref) => ref.watch(refundsRepositoryProvider).fetchRefunds(),
);

/// Single refund by id (autoDispose — resets when detail screen is gone).
final refundByIdProvider =
    FutureProvider.autoDispose.family<Refund?, String>((ref, id) async {
  final refunds = await ref.watch(refundsProvider.future);
  try {
    return refunds.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
  }
});

/// Temporary UI filter/sort/search state (autoDispose).
final refundsFilterProvider =
    StateNotifierProvider.autoDispose<RefundsFilterController, RefundsFilterState>(
  (ref) => RefundsFilterController(),
);

/// Derived filtered+sorted refunds (keeps build free of logic).
final filteredRefundsProvider =
    Provider.autoDispose<AsyncValue<List<Refund>>>((ref) {
  final refunds = ref.watch(refundsProvider);
  final filter = ref.watch(refundsFilterProvider);
  return refunds.whenData((list) => applyRefundFilter(list, filter));
});

/// Owns the refunds filter state; all updates produce a new state via copyWith.
class RefundsFilterController extends StateNotifier<RefundsFilterState> {
  RefundsFilterController() : super(const RefundsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);
  void setSort(String value) => state = state.copyWith(sort: value);
  void apply(RefundsFilterState next) => state = next;
  void reset() => state = const RefundsFilterState();
  void removeStatus() => state = state.copyWith(status: null);
  void removeReason() => state = state.copyWith(reason: null);
}
