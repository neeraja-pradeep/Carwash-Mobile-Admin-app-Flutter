import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/worker_profile_model.dart';

class WorkerProfileApi {
  late Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  WorkerProfileApi() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      extra: const {'withCredentials': true}, // web: send cookies cross-origin (no-op on mobile)
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add session interceptor
    _dio.interceptors.add(_SessionInterceptor());

    // Enable detailed logging in debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(_DebugLoggingInterceptor());
    }
  }

  /// Get worker profile
  Future<WorkerProfileModel> getWorkerProfile() async {
    try {
      final response = await _dio.get('/api/booking/v1/worker/profile/');
      return WorkerProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error
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

/// Session interceptor - adds sessionid and CSRF token to requests
class _SessionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('auth_sessions');
      final sessionData = box.get('current_session');

      if (sessionData != null) {
        final sessionId = sessionData['sessionId'];
        final csrfToken = sessionData['csrfToken'];

        if (sessionId != null) {
          String cookie = 'sessionid=$sessionId';
          if (csrfToken != null) {
            cookie += '; csrftoken=$csrfToken';
          }
          options.headers['Cookie'] = cookie;

          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method)) {
            if (csrfToken != null) {
              options.headers['X-CSRFToken'] = csrfToken;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Session interceptor error: $e');
    }

    super.onRequest(options, handler);
  }
}

/// Debug logging interceptor
class _DebugLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('═════════════════════════════════════════════════');
      print('🔵 API REQUEST: ${options.method}');
      print('Endpoint: ${options.path}');
      if (options.queryParameters.isNotEmpty) {
        print('Params: ${options.queryParameters}');
      }
      print('═════════════════════════════════════════════════');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('═════════════════════════════════════════════════');
      print('🟢 API SUCCESS: ${response.statusCode}');
      print('Endpoint: ${response.requestOptions.path}');
      print('Response: ${response.data}');
      print('═════════════════════════════════════════════════');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('═════════════════════════════════════════════════');
      print('🔴 API ERROR: ${err.response?.statusCode}');
      print('Endpoint: ${err.requestOptions.path}');
      print('Method: ${err.requestOptions.method}');
      print('Error: ${err.response?.data}');
      print('═════════════════════════════════════════════════');
    }
    super.onError(err, handler);
  }
}
