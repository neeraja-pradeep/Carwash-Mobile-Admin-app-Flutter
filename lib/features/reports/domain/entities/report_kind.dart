/// The six report types available in the Reports screen.
enum ReportKind {
  revenue,
  drivers,
  shops,
  commission,
  cancellation,
  inspection,
}

/// Human-readable label and description for each [ReportKind].
extension ReportKindMeta on ReportKind {
  String get label => switch (this) {
        ReportKind.revenue => 'Revenue',
        ReportKind.drivers => 'Drivers & Inspectors',
        ReportKind.shops => 'Shop Performance',
        ReportKind.commission => 'Commission / Settlement',
        ReportKind.cancellation => 'Cancellations',
        ReportKind.inspection => 'Inspections',
      };

  String get description => switch (this) {
        ReportKind.revenue => 'Gross, commission, refunds, net',
        ReportKind.drivers => 'Jobs, earnings, ratings',
        ReportKind.shops => 'Bookings & revenue per shop',
        ReportKind.commission => 'Platform vs shop earnings',
        ReportKind.cancellation => 'Cancelled & refunded bookings',
        ReportKind.inspection => 'Inspection jobs & fees',
      };
}
