import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/job_detail_model.dart';
import '../models/bill_model.dart';

class JobDetailApi {
  late Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static const String _basePath = '/api/booking/v1/driver-inspection-requests';

  JobDetailApi() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
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

  /// Get job detail by ID
  Future<JobDetailModel> getJobDetail(String jobId) async {
    try {
      final response = await _dio.get('$_basePath/$jobId/');
      return JobDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark arrived at job location
  Future<JobDetailModel> arrive(String jobId) async {
    try {
      final response = await _dio.post('$_basePath/$jobId/arrive/');
      return JobDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify start OTP
  Future<JobDetailModel> verifyStartOtp(String jobId, String otp) async {
    try {
      final response = await _dio.post(
        '$_basePath/$jobId/verify-start-otp/',
        data: {'otp': otp},
      );
      return JobDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify end OTP
  Future<JobDetailModel> verifyEndOtp(String jobId, String otp) async {
    try {
      final response = await _dio.post(
        '$_basePath/$jobId/verify-end-otp/',
        data: {'otp': otp},
      );
      return JobDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get final bill for completed job
  Future<BillModel> getFinalBill(String jobId) async {
    try {
      final response = await _dio.get('$_basePath/$jobId/final-bill/');
      return BillModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        // Try to extract error message from various possible fields
        final errorMessage = errorData['error'] ??
            errorData['detail'] ??
            errorData['otp'] ??
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
          // Build cookie string with both sessionid and csrftoken
          String cookie = 'sessionid=$sessionId';
          if (csrfToken != null) {
            cookie += '; csrftoken=$csrfToken';
          }
          options.headers['Cookie'] = cookie;

          // Add CSRF token header for unsafe methods
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

/// Debug logging interceptor - shows endpoint path and request/response details
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
