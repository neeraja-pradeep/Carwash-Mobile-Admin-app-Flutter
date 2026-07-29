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

  /// `any` | `7` | `30` | `90` — window on the payout date, chosen in the
  /// filter sheet. Defaults to `any`: the API's own default is 90 days, which
  /// silently hid older payouts before an admin had chosen anything.
  final String date;
  final int page;
  final int pageSize;

  const PayoutLogFilter({
    this.search,
    this.status,
    this.shop,
    this.sort,
    this.date = 'any',
    this.page = 1,
    this.pageSize = 10,
  });

  /// Alias for search (UI compatibility)
  String? get query => search;

  /// The API's `days` window. There is no "off" switch — `days=0` returns an
  /// empty window rather than everything — so all time is a century-wide one.
  int get days => switch (date) {
        '7' => 7,
        '30' => 30,
        '90' => 90,
        _ => 36500,
      };

  /// Human label for the selected window — chip row and top bar subtitle.
  String get dateLabel => switch (date) {
        '7' => 'Last 7 days',
        '30' => 'Last 30 days',
        '90' => 'Last 90 days',
        _ => 'All time',
      };

  /// Count of active filters
  int get activeCount {
    int count = 0;
    if (search != null && search!.isNotEmpty) count++;
    if (status != null && status!.isNotEmpty) count++;
    if (shop != null && shop!.isNotEmpty) count++;
    if (sort != null && sort != 'recent') count++;
    if (date != 'any') count++;
    return count;
  }

  /// CopyWith for filter updates.
  ///
  /// [status] and [shop] are nullable *values*, so they take a sentinel —
  /// passing null must clear them (deselecting a chip), not be read as
  /// "unchanged".
  PayoutLogFilter copyWith({
    String? search,
    Object? status = _sentinel,
    Object? shop = _sentinel,
    String? sort,
    String? date,
    int? page,
    int? pageSize,
  }) {
    return PayoutLogFilter(
      search: search ?? this.search,
      status: status == _sentinel ? this.status : status as String?,
      shop: shop == _sentinel ? this.shop : shop as String?,
      sort: sort ?? this.sort,
      date: date ?? this.date,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Reset all filters to defaults
  PayoutLogFilter reset() {
    return const PayoutLogFilter();
  }

  static const Object _sentinel = Object();
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

  /// `any` | `7` | `30` | `90`.
  void setDate(String date) {
    state = state.copyWith(date: date, page: 1);
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
