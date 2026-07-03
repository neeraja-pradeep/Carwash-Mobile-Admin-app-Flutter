import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/schedule_day_model.dart';

class ScheduleApi {
  late Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static const String _scheduleBasePath = '/api/booking/v1/worker/schedule';
  static const String _availableJobsPath = '/api/booking/v1/worker/available-jobs';
  static const String _claimCarwashPath = '/api/booking/v1/worker/claim/carwash';
  static const String _claimDriverHirePath = '/api/booking/v1/worker/claim/driver-inspection';
  static const String _carwashSummaryPath = '/api/booking/v1/worker/carwash';

  ScheduleApi() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      extra: const {'withCredentials': true}, // web: send cookies cross-origin (no-op on mobile)
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(_SessionInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(_DebugLoggingInterceptor());
    }
  }

  /// Get worker schedule with upcoming and completed jobs
  Future<ScheduleResponseModel> getSchedule({
    String? from,
    String? to,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final response = await _dio.get(
        _scheduleBasePath,
        queryParameters: queryParams,
      );
      return ScheduleResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get available/claimable jobs
  Future<Map<String, dynamic>> getAvailableJobs({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        _availableJobsPath,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Claim a carwash job
  Future<Map<String, dynamic>> claimCarwashJob(String bookingId) async {
    try {
      final response = await _dio.post('$_claimCarwashPath/$bookingId/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Claim a driver-hire/inspection job
  Future<Map<String, dynamic>> claimDriverHireJob(String bookingId) async {
    try {
      final response = await _dio.post('$_claimDriverHirePath/$bookingId/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get carwash job summary
  Future<Map<String, dynamic>> getCarwashSummary(String bookingId) async {
    try {
      final response = await _dio.get('$_carwashSummaryPath/$bookingId/summary/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
      print('Error: ${err.response?.data}');
      print('═════════════════════════════════════════════════');
    }
    super.onError(err, handler);
  }
}
