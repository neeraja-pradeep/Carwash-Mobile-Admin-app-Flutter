import '../../domain/entities/daily_summary.dart';
import '../../domain/entities/report_data.dart';

// ─── Shared helpers ───────────────────────────────────────────────────────────

/// Parse a money/decimal value that the API sends as a string (`"1200.00"`),
/// tolerating raw numbers too. Returns 0 on failure.
num _toNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return double.tryParse(value)?.round() ?? 0;
  return 0;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _toStr(dynamic value) => value?.toString() ?? '';

ReportPeriod _periodFromJson(Map<String, dynamic>? json) {
  final j = json ?? const {};
  return ReportPeriod(
    key: _toStr(j['key']),
    label: _toStr(j['label']),
    start: _toStr(j['start']),
    end: _toStr(j['end']),
  );
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : const {};

List<Map<String, dynamic>> _listOfMaps(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

// ─── Revenue ──────────────────────────────────────────────────────────────────

class RevenueReportResponse {
  RevenueReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory RevenueReportResponse.fromJson(Map<String, dynamic> json) =>
      RevenueReportResponse(json);

  RevenueReport toDomain() {
    final k = _map(_json['kpis']);
    return RevenueReport(
      period: _periodFromJson(_map(_json['period'])),
      kpis: RevenueSummary(
        gross: _toNum(k['gross']),
        commission: _toNum(k['commission']),
        refunds: _toNum(k['refunds']),
        net: _toNum(k['net_revenue']),
      ),
      byService: _listOfMaps(_json['rows'])
          .map((r) => ServiceStat(
                name: _toStr(r['service']),
                count: _toInt(r['count']),
                revenue: _toNum(r['revenue']),
              ))
          .toList(),
    );
  }
}

// ─── Drivers & Inspectors ─────────────────────────────────────────────────────

class DriversReportResponse {
  DriversReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory DriversReportResponse.fromJson(Map<String, dynamic> json) =>
      DriversReportResponse(json);

  DriversReport toDomain() {
    final k = _map(_json['kpis']);
    final rows = _map(_json['rows']);
    return DriversReport(
      period: _periodFromJson(_map(_json['period'])),
      activeDrivers: _toInt(k['active_drivers']),
      hireJobs: _toInt(k['hire_jobs']),
      driverPayout: _toNum(k['driver_payout']),
      inspectorPayout: _toNum(k['inspector_payout']),
      drivers: _listOfMaps(rows['drivers'])
          .map((r) => DriverPerfRow(
                name: _toStr(r['name']),
                wash: _toInt(r['wash']),
                hire: _toInt(r['hire']),
                earnings: _toNum(r['earnings']),
                rating: _toDoubleOrNull(r['rating']),
              ))
          .toList(),
      inspectors: _listOfMaps(rows['inspectors'])
          .map((r) => InspectorPerfRow(
                name: _toStr(r['name']),
                inspections: _toInt(r['inspections']),
                payout: _toNum(r['payout']),
                rating: _toDoubleOrNull(r['rating']),
              ))
          .toList(),
    );
  }
}

// ─── Shop Performance ─────────────────────────────────────────────────────────

class ShopPerformanceReportResponse {
  ShopPerformanceReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory ShopPerformanceReportResponse.fromJson(Map<String, dynamic> json) =>
      ShopPerformanceReportResponse(json);

  ShopPerformanceReport toDomain() {
    final k = _map(_json['kpis']);
    return ShopPerformanceReport(
      period: _periodFromJson(_map(_json['period'])),
      shopsActive: _toInt(k['shops_active']),
      totalBookings: _toInt(k['total_bookings']),
      totalRevenue: _toNum(k['total_revenue']),
      byShop: _listOfMaps(_json['rows'])
          .map((r) => ShopStat(
                shop: _toStr(r['shop']),
                bookings: _toInt(r['bookings']),
                revenue: _toNum(r['revenue']),
              ))
          .toList(),
    );
  }
}

// ─── Commission / Settlement ──────────────────────────────────────────────────

class CommissionReportResponse {
  CommissionReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory CommissionReportResponse.fromJson(Map<String, dynamic> json) =>
      CommissionReportResponse(json);

  CommissionReport toDomain() {
    final k = _map(_json['kpis']);
    return CommissionReport(
      period: _periodFromJson(_map(_json['period'])),
      platformCommission: _toNum(k['platform_commission']),
      shopEarnings: _toNum(k['shop_earnings']),
      refundsDeducted: _toNum(k['refunds_deducted']),
      netSettled: _toNum(k['net_settled']),
      byShop: _listOfMaps(_json['rows'])
          .map((r) => CommissionShopRow(
                shop: _toStr(r['shop']),
                gross: _toNum(r['gross']),
                commission: _toNum(r['commission']),
              ))
          .toList(),
    );
  }
}

// ─── Cancellations ────────────────────────────────────────────────────────────

class CancellationsReportResponse {
  CancellationsReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory CancellationsReportResponse.fromJson(Map<String, dynamic> json) =>
      CancellationsReportResponse(json);

  CancellationsReport toDomain() {
    final k = _map(_json['kpis']);
    return CancellationsReport(
      period: _periodFromJson(_map(_json['period'])),
      cancelled: _toInt(k['cancelled']),
      cancelRatePercent: _toDoubleOrNull(k['cancel_rate_percent']) ?? 0,
      refundsIssued: _toNum(k['refunds_issued']),
      totalBookings: _toInt(k['total_bookings']),
      reasons: _listOfMaps(_json['rows'])
          .map((r) => CancellationReasonRow(
                reason: _toStr(r['reason']),
                count: _toInt(r['count']),
              ))
          .toList(),
    );
  }
}

// ─── Inspections ──────────────────────────────────────────────────────────────

class InspectionsReportResponse {
  InspectionsReportResponse(this._json);
  final Map<String, dynamic> _json;

  factory InspectionsReportResponse.fromJson(Map<String, dynamic> json) =>
      InspectionsReportResponse(json);

  InspectionsReport toDomain() {
    final k = _map(_json['kpis']);
    return InspectionsReport(
      period: _periodFromJson(_map(_json['period'])),
      inspections: _toInt(k['inspections']),
      inspectorPayout: _toNum(k['inspector_payout']),
      avgFee: _toNum(k['avg_fee']),
      activeInspectors: _toInt(k['active_inspectors']),
      rows: _listOfMaps(_json['rows'])
          .map((r) => InspectionRow(
                name: _toStr(r['name']),
                inspections: _toInt(r['inspections']),
                payout: _toNum(r['payout']),
              ))
          .toList(),
    );
  }
}
