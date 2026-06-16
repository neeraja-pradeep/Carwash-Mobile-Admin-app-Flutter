import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payout.dart';
import '../../domain/repositories/payouts_repository.dart';
import '../../infrastructure/data_sources/local/payouts_local_ds.dart';
import '../../infrastructure/repositories/payouts_repository_impl.dart';
import '../states/payouts_filter_state.dart';

/// Local data source provider.
final payoutsLocalDsProvider = Provider<PayoutsLocalDs>(
  (ref) => const PayoutsLocalDs(),
);

/// The payouts repository (domain contract → infrastructure impl).
final payoutsRepositoryProvider = Provider<PayoutsRepository>(
  (ref) => PayoutsRepositoryImpl(ref.watch(payoutsLocalDsProvider)),
);

/// All payouts (read). Kept alive so back-navigation is instant.
final payoutsProvider = FutureProvider<List<Payout>>(
  (ref) => ref.watch(payoutsRepositoryProvider).fetchPayouts(),
);

/// Single payout by id (autoDispose — resets when detail screen is gone).
final payoutByIdProvider =
    FutureProvider.autoDispose.family<Payout?, String>((ref, id) async {
  final payouts = await ref.watch(payoutsProvider.future);
  try {
    return payouts.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

/// Temporary UI filter/sort/search state (autoDispose).
final payoutsFilterProvider =
    StateNotifierProvider.autoDispose<PayoutsFilterController, PayoutsFilterState>(
  (ref) => PayoutsFilterController(),
);

/// Owns the payouts filter state; all updates produce a new state via copyWith.
class PayoutsFilterController extends StateNotifier<PayoutsFilterState> {
  PayoutsFilterController() : super(const PayoutsFilterState());

  void setQuery(String value) => state = state.copyWith(query: value);
  void setSort(String value) => state = state.copyWith(sort: value);
  void apply(PayoutsFilterState next) => state = next;
  void reset() => state = const PayoutsFilterState();
  void removeStatus() => state = state.copyWith(status: null);
  void removeShop() => state = state.copyWith(shopId: null);
}
