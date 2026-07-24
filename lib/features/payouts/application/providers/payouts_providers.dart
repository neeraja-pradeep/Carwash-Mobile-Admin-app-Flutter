import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/payouts_repository.dart';
import '../../infrastructure/repositories/payouts_repository_impl.dart';

/// Payout log repository provider (API exclusive)
final payoutsRepositoryProvider = Provider<PayoutsRepository>((ref) {
  return PayoutsRepositoryImpl();
});

/// Payout log filter state (search, filters, sort, pagination)
class PayoutLogFilter {
  final String? search; // "query" alias for UI compatibility
  final String? status;
  final String? shop;
  final String? sort;
  final int? days;
  final int page;
  final int pageSize;

  const PayoutLogFilter({
    this.search,
    this.status,
    this.shop,
    this.sort,
    this.days,
    this.page = 1,
    this.pageSize = 10,
  });

  /// Alias for search (UI compatibility)
  String? get query => search;

  /// Count of active filters
  int get activeCount {
    int count = 0;
    if (search != null && search!.isNotEmpty) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (shop != null && shop!.isNotEmpty) count++;
    if (sort != null && sort != 'recent') count++;
    if (days != null && days != 90) count++;
    return count;
  }

  /// CopyWith for filter updates
  PayoutLogFilter copyWith({
    String? search,
    String? status,
    String? shop,
    String? sort,
    int? days,
    int? page,
    int? pageSize,
  }) {
    return PayoutLogFilter(
      search: search ?? this.search,
      status: status ?? this.status,
      shop: shop ?? this.shop,
      sort: sort ?? this.sort,
      days: days ?? this.days,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Reset all filters to defaults
  PayoutLogFilter reset() {
    return const PayoutLogFilter();
  }
}

/// Filter controller with convenient methods for UI
class PayoutLogFilterController extends StateNotifier<PayoutLogFilter> {
  PayoutLogFilterController() : super(const PayoutLogFilter());

  void setQuery(String query) {
    state = state.copyWith(search: query, page: 1);
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort, page: 1);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setShop(String? shop) {
    state = state.copyWith(shop: shop, page: 1);
  }

  void reset() {
    state = const PayoutLogFilter();
  }

  void goToPage(int page) {
    state = state.copyWith(page: page);
  }

  /// Apply a new filter state (for batch updates from filter sheet)
  void apply(PayoutLogFilter filter) {
    state = filter.copyWith(page: 1);
  }
}

/// Payout log filter state provider (autoDispose)
final payoutLogFilterProvider =
    StateNotifierProvider.autoDispose<PayoutLogFilterController, PayoutLogFilter>(
  (ref) => PayoutLogFilterController(),
);

/// Payout log data fetcher with filters (autoDispose)
final payoutLogProvider =
    FutureProvider.autoDispose<PayoutsPage>((ref) async {
  final repository = ref.watch(payoutsRepositoryProvider);
  final filter = ref.watch(payoutLogFilterProvider);

  return repository.fetchPayoutLog(
    search: filter.search,
    status: filter.status,
    shop: filter.shop,
    sort: filter.sort,
    days: filter.days,
    page: filter.page,
    pageSize: filter.pageSize,
  );
});

/// Refetches the payouts log. Shared by pull-to-refresh and the navigate-back
/// refresh wired up in `app_router.dart`.
Future<void> refreshPayouts(WidgetRef ref) async {
  ref.invalidate(payoutLogProvider);
  await ref.read(payoutLogProvider.future);
}
