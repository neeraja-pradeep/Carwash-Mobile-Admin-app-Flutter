import '../../domain/entities/report_data.dart';
import '../../domain/repositories/reports_repository.dart';
import '../data_sources/reports_api.dart';

/// API-backed [ReportsRepository] — each method hits one `/api/reports/v1/`
/// endpoint and maps the response to its domain entity.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({ReportsApi? api}) : _api = api ?? ReportsApi();

  final ReportsApi _api;

  @override
  Future<RevenueReport> fetchRevenue(ReportQuery query) async =>
      (await _api.getRevenue(query)).toDomain();

  @override
  Future<DriversReport> fetchDriversInspectors(ReportQuery query) async =>
      (await _api.getDriversInspectors(query)).toDomain();

  @override
  Future<ShopPerformanceReport> fetchShopPerformance(ReportQuery query) async =>
      (await _api.getShopPerformance(query)).toDomain();

  @override
  Future<CommissionReport> fetchCommission(ReportQuery query) async =>
      (await _api.getCommission(query)).toDomain();

  @override
  Future<CancellationsReport> fetchCancellations(ReportQuery query) async =>
      (await _api.getCancellations(query)).toDomain();

  @override
  Future<InspectionsReport> fetchInspections(ReportQuery query) async =>
      (await _api.getInspections(query)).toDomain();

  @override
  Future<ReportExport> exportCsv(String name, ReportQuery query) =>
      _api.exportCsv(name, query);
}
