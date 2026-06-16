/// Point-in-time carwash operational snapshot for today (from `data.jsx` SNAPSHOT).
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.bookingsToday,
    required this.waiting,
    required this.inProgress,
    required this.doneToday,
    required this.activeNow,
    required this.overdue,
    required this.pendingRefunds,
    required this.pendingRefundAmt,
  });

  /// Total bookings received for today.
  final int bookingsToday;

  /// Bookings in "waiting" state.
  final int waiting;

  /// Bookings currently in-progress.
  final int inProgress;

  /// Bookings completed today.
  final int doneToday;

  /// Vehicles being washed right now.
  final int activeNow;

  /// Bookings that are past their scheduled slot.
  final int overdue;

  /// Number of refund requests pending approval.
  final int pendingRefunds;

  /// Total amount (₹) across all pending refunds.
  final num pendingRefundAmt;
}
