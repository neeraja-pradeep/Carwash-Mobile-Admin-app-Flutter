import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/notifications_response_model.dart';

class NotificationsApi {
  late Dio _dio;

  static const String _unreadCountPath = '/api/accounts/v1/notifications/unread-count/';
  static const String _notificationsPath = '/api/accounts/v1/notifications/';
  static const String _markAllReadPath = '/api/accounts/v1/notifications/read-all/';

  NotificationsApi() {
    _dio = HttpClient().dio;
  }

  /// Get unread notification count.
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(_unreadCountPath);
      final data = response.data as Map<String, dynamic>;
      return data['unread'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get paginated notifications with optional filters.
  Future<NotificationsListResponse> getNotifications({
    int page = 1,
    int pageSize = 10,
    bool? isRead,
    String? kind,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (isRead != null) {
        params['is_read'] = isRead;
      }

      if (kind != null && kind.isNotEmpty) {
        params['kind'] = kind;
      }

      final response = await _dio.get(
        _notificationsPath,
        queryParameters: params,
      );

      return NotificationsListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post(
        '$_notificationsPath$notificationId/read/',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read.
  Future<int> markAllAsRead() async {
    try {
      final response = await _dio.post(_markAllReadPath);
      final data = response.data as Map<String, dynamic>;
      return data['updated'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error.
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
