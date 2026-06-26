import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/hiring_rates_model.dart';
import '../models/notification_preference_model.dart';
import '../models/org_info_model.dart';
import '../models/serviceability_area_model.dart';

/// API client for the Settings screen. Spans four backends (org-info,
/// hiring-rates, serviceability-areas, notification-preferences) but maps to a
/// single Settings feature.
class SettingsApi {
  late Dio _dio;

  static const String _orgInfoPath = '/api/accounts/v1/org-info/';
  static const String _hiringRatesPath = '/api/booking/v1/hiring-rates/';
  static const String _areasPath = '/api/shop/v1/serviceability-areas/';
  static const String _notifPrefsPath =
      '/api/accounts/v1/notification-preferences/';

  SettingsApi() {
    _dio = HttpClient().dio;
  }

  // ── Org info ──────────────────────────────────────────────────────────────

  Future<OrgInfoModel> getOrgInfo() async {
    try {
      final response = await _dio.get(_orgInfoPath);
      return OrgInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<OrgInfoModel> patchOrgInfo(Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(_orgInfoPath, data: body);
      return OrgInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Hiring rates ──────────────────────────────────────────────────────────

  Future<HiringRatesModel> getHiringRates() async {
    try {
      final response = await _dio.get(_hiringRatesPath);
      return HiringRatesModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<HiringRatesModel> patchHiringRates(Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(_hiringRatesPath, data: body);
      return HiringRatesModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Service areas ─────────────────────────────────────────────────────────

  Future<List<ServiceabilityAreaModel>> getServiceAreas({String? type}) async {
    try {
      final response = await _dio.get(
        _areasPath,
        queryParameters: {
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      return parseServiceabilityAreas(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceabilityAreaModel> createServiceArea(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(_areasPath, data: body);
      return ServiceabilityAreaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceabilityAreaModel> updateServiceArea(
      int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch('$_areasPath$id/', data: body);
      return ServiceabilityAreaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteServiceArea(int id) async {
    try {
      await _dio.delete('$_areasPath$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Notification preferences ──────────────────────────────────────────────

  Future<NotificationPreferenceModel> getNotificationPreferences() async {
    try {
      final response = await _dio.get(_notifPrefsPath);
      return NotificationPreferenceModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<NotificationPreferenceModel> patchNotificationPreferences(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(_notifPrefsPath, data: body);
      return NotificationPreferenceModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handling ────────────────────────────────────────────────────────

  /// Surfaces field-keyed 400/403/409 validation messages (the write
  /// serializers return `{field: [message]}` maps) so the UI can show a useful
  /// toast.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 403) {
        return Exception('You don\'t have permission to make this change.');
      }
      if (statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }

      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        final direct =
            errorData['error'] ?? errorData['detail'] ?? errorData['message'];
        if (direct != null) {
          return Exception(direct.toString());
        }

        for (final entry in errorData.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return Exception('${entry.key}: ${value.first}');
          }
          if (value is String && value.isNotEmpty) {
            return Exception('${entry.key}: $value');
          }
        }
        return Exception('An error occurred');
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
