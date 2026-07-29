import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/refund.dart';
import '../../domain/repositories/refunds_repository.dart';
import '../../infrastructure/repositories/refunds_repository_impl.dart';
import '../states/refunds_filter_state.dart';

/// The refunds repository (domain contract → infrastructure impl).
final refundsRepositoryProvider = Provider<RefundsRepository>(
  (ref) => RefundsRepositoryImpl(),
);

/// All refunds (read). Auto-dispose to prevent unwanted API calls.
///
/// The list is not date-scoped: the API windows `created_at` to 30 days unless
/// told otherwise, which silently hid every older refund, so `days: 0` (all
/// time) is always sent.
final refundsProvider = FutureProvider.autoDispose<List<Refund>>(
  (ref) => ref.watch(refundsRepositoryProvider).fetchRefunds(days: 0),
);

/// Single refund by id or `RF-…` reference — hits the detail endpoint.
/// `.family` keyed by the detail key (reference preferred over numeric id).
final refundByIdProvider =
    FutureProvider.autoDispose.family<Refund?, String>((ref, idOrReference) {
  return ref.watch(refundsRepositoryProvider).getRefundDetail(idOrReference);
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

/// Mutations (approve / mark-paid / create / decline) live on the repository.
/// These helpers run the call then invalidate the list (and the affected
/// detail entry) so screens refetch fresh data. Errors propagate to the caller.
class RefundActions {
  RefundActions(this._ref);

  final Ref _ref;

  RefundsRepository get _repo => _ref.read(refundsRepositoryProvider);

  void _refresh([String? detailKey]) {
    _ref.invalidate(refundsProvider);
    if (detailKey != null && detailKey.isNotEmpty) {
      _ref.invalidate(refundByIdProvider(detailKey));
    }
  }

  Future<Refund> approve({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
    String? detailKey,
  }) async {
    final r = await _repo.approve(
      bookingReference: bookingReference,
      percent: percent,
      amount: amount,
      reason: reason,
      comment: comment,
    );
    _refresh(detailKey ?? r.detailKey);
    return r;
  }

  Future<Refund> markPaid({
    required String refundRef,
    required String paymentProofReference,
    String? screenshotPath,
    bool manual = false,
    String? detailKey,
  }) async {
    final r = await _repo.markPaid(
      refundRef: refundRef,
      paymentProofReference: paymentProofReference,
      screenshotPath: screenshotPath,
      manual: manual,
    );
    _refresh(detailKey ?? r.detailKey);
    return r;
  }

  Future<Refund> createStandalone({
    required String bookingReference,
    int? percent,
    int? amount,
    String? reason,
    String? comment,
    bool manual = false,
    String? paymentKind,
  }) async {
    final r = await _repo.createStandalone(
      bookingReference: bookingReference,
      percent: percent,
      amount: amount,
      reason: reason,
      comment: comment,
      manual: manual,
      paymentKind: paymentKind,
    );
    _refresh(r.detailKey);
    return r;
  }

  Future<Refund> decline({
    required String bookingReference,
    String? reason,
    String? comment,
    String? detailKey,
  }) async {
    final r = await _repo.decline(
      bookingReference: bookingReference,
      reason: reason,
      comment: comment,
    );
    _refresh(detailKey ?? r.detailKey);
    return r;
  }
}

/// Action helpers for refund mutations.
final refundActionsProvider =
    Provider<RefundActions>((ref) => RefundActions(ref));

/// Refetches the refunds list. Shared by pull-to-refresh and the navigate-back
/// refresh wired up in `app_router.dart`.
Future<void> refreshRefunds(WidgetRef ref) async {
  ref.invalidate(refundsProvider);
  await ref.read(refundsProvider.future);
}
