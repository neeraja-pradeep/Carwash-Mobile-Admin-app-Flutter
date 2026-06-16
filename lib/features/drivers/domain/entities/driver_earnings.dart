/// A recorded payout to a driver.
class DriverPayout {
  const DriverPayout({
    required this.amount,
    required this.date,
    required this.utr,
  });

  final int amount;
  final String date;
  final String utr;
}

/// An earnings breakdown row (e.g. carwash jobs, driver hire, incentives).
class EarningsBreakdownRow {
  const EarningsBreakdownRow({
    required this.label,
    required this.count,
    required this.amount,
  });

  final String label;
  final int count;
  final int amount;
}

/// The signed-in driver's earnings (drives the Earnings tab).
class DriverEarnings {
  const DriverEarnings({
    required this.todayTotal,
    required this.weekTotal,
    required this.pending,
    required this.lastPayout,
    required this.byDay,
    required this.breakdown,
  });

  final int todayTotal;
  final int weekTotal;
  final int pending;
  final DriverPayout lastPayout;

  /// `(weekday, amount)` pairs for the bar chart.
  final List<(String, int)> byDay;
  final List<EarningsBreakdownRow> breakdown;
}
