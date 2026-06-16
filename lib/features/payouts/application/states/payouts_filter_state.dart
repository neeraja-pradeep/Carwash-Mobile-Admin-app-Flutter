import '../../domain/entities/payout.dart';

/// Immutable filter/sort/search state for the Payouts list.
class PayoutsFilterState {
  const PayoutsFilterState({
    this.status,
    this.shopId,
    this.query = '',
    this.sort = 'recent',
  });

  /// `null` = all; `pending` | `paid`
  final String? status;

  /// `null` = all; shop id string
  final String? shopId;
  final String query;

  /// `recent` | `net_hi` | `net_lo` | `shop`
  final String sort;

  int get activeCount =>
      (status != null ? 1 : 0) + (shopId != null ? 1 : 0);

  PayoutsFilterState copyWith({
    Object? status = _sentinel,
    Object? shopId = _sentinel,
    String? query,
    String? sort,
  }) {
    return PayoutsFilterState(
      status: status == _sentinel ? this.status : status as String?,
      shopId: shopId == _sentinel ? this.shopId : shopId as String?,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }

  static const Object _sentinel = Object();
}

/// Applies a [PayoutsFilterState] to a payout list (search → filters → sort).
List<Payout> applyPayoutFilter(
  List<Payout> source,
  PayoutsFilterState f, {
  required String Function(String shopId) shopName,
}) {
  final q = f.query.trim().toLowerCase();
  final filtered = source.where((p) {
    if (f.status != null && p.status != f.status) return false;
    if (f.shopId != null && p.shopId != f.shopId) return false;
    if (q.isNotEmpty) {
      final nm = shopName(p.shopId).toLowerCase();
      if (!nm.contains(q) && !(p.utr.toLowerCase().contains(q))) return false;
    }
    return true;
  }).toList();

  switch (f.sort) {
    case 'net_hi':
      filtered.sort((a, b) => b.calc.net.compareTo(a.calc.net));
    case 'net_lo':
      filtered.sort((a, b) => a.calc.net.compareTo(b.calc.net));
    case 'shop':
      filtered.sort(
          (a, b) => shopName(a.shopId).compareTo(shopName(b.shopId)));
    default:
      filtered.sort((a, b) => b.id.compareTo(a.id));
  }
  return filtered;
}
