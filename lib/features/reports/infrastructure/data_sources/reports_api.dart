import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/report_response_models.dart';

/// Data source for the `reports` app — 6 JSON report endpoints plus their CSV
/// exports, all under `/api/reports/v1/`. Superadmin-only; auth is carried
/// automatically by the shared [HttpClient] interceptors.
class ReportsApi {
  late final Dio _dio;

  static const String _basePath = '/api/reports/v1';

  ReportsApi() {
    _dio = HttpClient().dio;
  }

  /// Build the period query params from a [ReportQuery]. A custom range
  /// (`date_from`/`date_to`) overrides the preset `period`.
  Map<String, dynamic> _params(ReportQuery q) {
    if (q.isCustom) {
      return {'date_from': q.from, 'date_to': q.to};
    }
    return {if (q.period != null && q.period!.isNotEmpty) 'period': q.period};
  }

  Future<RevenueReportResponse> getRevenue(ReportQuery q) =>
      _getJson('revenue', q, RevenueReportResponse.fromJson);

  Future<DriversReportResponse> getDriversInspectors(ReportQuery q) =>
      _getJson('drivers-inspectors', q, DriversReportResponse.fromJson);

  Future<ShopPerformanceReportResponse> getShopPerformance(ReportQuery q) =>
      _getJson('shop-performance', q, ShopPerformanceReportResponse.fromJson);

  Future<CommissionReportResponse> getCommission(ReportQuery q) =>
      _getJson('commission', q, CommissionReportResponse.fromJson);

  Future<CancellationsReportResponse> getCancellations(ReportQuery q) =>
      _getJson('cancellations', q, CancellationsReportResponse.fromJson);

  Future<InspectionsReportResponse> getInspections(ReportQuery q) =>
      _getJson('inspections', q, InspectionsReportResponse.fromJson);

  Future<T> _getJson<T>(
    String name,
    ReportQuery q,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await _dio.get(
        '$_basePath/$name/',
        queryParameters: _params(q),
      );
      return parse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download a report's CSV export as raw bytes. [name] is the report slug.
  Future<ReportExport> exportCsv(String name, ReportQuery q) async {
    try {
      final response = await _dio.get<List<int>>(
        '$_basePath/$name/export/',
        queryParameters: _params(q),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? <int>[];
      final filename = _filenameFromHeaders(response.headers) ??
          '${name}_${q.isCustom ? '${q.from}_${q.to}' : (q.period ?? 'today')}.csv';
      return (bytes: bytes, filename: filename);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Pull `filename="…"` out of a `content-disposition` header, if present.
  String? _filenameFromHeaders(Headers headers) {
    final disposition = headers.value('content-disposition');
    if (disposition == null) return null;
    final match =
        RegExp(r'filename\*?=(?:UTF-8'')?"?([^";]+)"?').firstMatch(disposition);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return Uri.decodeComponent(raw);
  }

  /// Handle DioException and throw an appropriate error.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }
      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        final errorMessage = errorData['error'] ??
            errorData['detail'] ??
            errorData['message'] ??
            'An error occurred';
        return Exception(errorMessage);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        return Exception(
          'Error ${e.response?.statusCode}: ${e.response?.statusMessage}',
        );
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.badCertificate:
        return Exception('Certificate error');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your internet.');
      case DioExceptionType.unknown:
        return Exception(e.message ?? 'Unknown error occurred');
    }
  }
}
