import '../entities/report_data.dart';

/// Selected reporting window. Either a preset [period] (`today`, `last_7`,
/// `last_30`, `this_month`) or an explicit [from]/[to] custom range
/// (`YYYY-MM-DD`, which overrides the preset). Value equality makes it a safe
/// Riverpod family key.
class ReportQuery {
  const ReportQuery({this.period, this.from, this.to});

  final String? period;
  final String? from;
  final String? to;

  bool get isCustom => from != null && to != null;

  @override
  bool operator ==(Object other) =>
      other is ReportQuery &&
      other.period == period &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(period, from, to);
}

/// A downloaded export file (raw bytes + suggested filename).
typedef ReportExport = ({List<int> bytes, String filename});

/// Abstract contract — implemented in infrastructure; called from application.
abstract interface class ReportsRepository {
  Future<RevenueReport> fetchRevenue(ReportQuery query);
  Future<DriversReport> fetchDriversInspectors(ReportQuery query);
  Future<ShopPerformanceReport> fetchShopPerformance(ReportQuery query);
  Future<CommissionReport> fetchCommission(ReportQuery query);
  Future<CancellationsReport> fetchCancellations(ReportQuery query);
  Future<InspectionsReport> fetchInspections(ReportQuery query);

  /// Download a report's CSV export. [name] ∈ `revenue`,
  /// `drivers-inspectors`, `shop-performance`, `commission`, `cancellations`,
  /// `inspections`.
  Future<ReportExport> exportCsv(String name, ReportQuery query);
}
