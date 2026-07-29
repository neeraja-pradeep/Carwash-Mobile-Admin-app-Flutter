import '../../domain/entities/refund.dart';

/// Immutable filter/sort/search state for the Refunds list.
class RefundsFilterState {
  const RefundsFilterState({
    this.status,
    this.reason,
    this.query = '',
    this.sort = 'recent',
  });

  /// `null` = all; `requested` | `approved` | `paid` | `declined`
  final String? status;

  /// `null` = all; one of kRefundReasons
  final String? reason;
  final String query;

  /// `recent` | `amount_hi` | `amount_lo` | `status`
  final String sort;

  int get activeCount =>
      (status != null ? 1 : 0) + (reason != null ? 1 : 0);

  /// True when the admin has actually narrowed the list themselves.
  bool get hasUserFilter => activeCount > 0 || query.trim().isNotEmpty;

  RefundsFilterState copyWith({
    Object? status = _sentinel,
    Object? reason = _sentinel,
    String? query,
    String? sort,
  }) {
    return RefundsFilterState(
      status: status == _sentinel ? this.status : status as String?,
      reason: reason == _sentinel ? this.reason : reason as String?,
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }

  static const Object _sentinel = Object();
}

/// Applies a [RefundsFilterState] to a refund list (search → filters → sort).
List<Refund> applyRefundFilter(List<Refund> source, RefundsFilterState f) {
  final q = f.query.trim().toLowerCase();
  final filtered = source.where((r) {
    if (f.status != null && r.status != f.status) return false;
    if (f.reason != null && r.reason != f.reason) return false;
    if (q.isNotEmpty &&
        !r.bookingId.toLowerCase().contains(q) &&
        !r.customer.name.toLowerCase().contains(q) &&
        !r.customer.phone.contains(q)) {
      return false;
    }
    return true;
  }).toList();

  switch (f.sort) {
    case 'amount_hi':
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    case 'amount_lo':
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    case 'status':
      filtered.sort((a, b) => a.status.compareTo(b.status));
    default:
      filtered.sort((a, b) => b.id.compareTo(a.id));
  }
  return filtered;
}
