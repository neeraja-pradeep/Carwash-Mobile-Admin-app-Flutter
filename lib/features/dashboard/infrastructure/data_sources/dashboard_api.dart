import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/activity_response_model.dart';
import '../models/dashboard_response_model.dart';

class DashboardApi {
  late Dio _dio;

  static const String _profilePath = '/api/accounts/v1/profile/';
  static const String _notificationsPath = '/api/accounts/v1/notifications/unread-count/';
  static const String _dashboardPath = '/api/booking/v1/admin/dashboard/';
  static const String _recentActivityPath = '/api/booking/v1/admin/recent-activity/';
  static const String _activitiesPath = '/api/booking/v1/activities/';

  DashboardApi() {
    // Use shared HTTP client to maintain session cookies across the app
    _dio = HttpClient().dio;
  }

  /// Get current user profile (name, avatar).
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(_profilePath);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get unread notification count.
  Future<int> getNotificationCount() async {
    try {
      final response = await _dio.get(_notificationsPath);
      final data = response.data as Map<String, dynamic>;
      return data['unread'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get dashboard KPI snapshot (includes both carwash and hiring).
  Future<DashboardResponseModel> getDashboardSnapshot() async {
    try {
      final response = await _dio.get(_dashboardPath);
      return DashboardResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get recent activity feed (top 5 items).
  Future<List<ActivityResponseModel>> getRecentActivity() async {
    try {
      final response = await _dio.get(_recentActivityPath);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => ActivityResponseModel.fromJson(
            item as Map<String, dynamic>,
          ))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get paginated activity feed (for "View all").
  Future<Map<String, dynamic>> getActivities({int page = 1}) async {
    try {
      final response = await _dio.get(
        _activitiesPath,
        queryParameters: {'page': page},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error.
  Exception _handleError(DioException e) {
    if (e.response != null) {
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
