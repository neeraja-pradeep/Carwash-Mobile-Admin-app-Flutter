import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_response_model.dart';

class AuthApi {
  late Dio _dio;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static const String _sendOtpPath = '/api/accounts/v1/send-otp/';
  static const String _verifyOtpPath = '/api/accounts/v1/verify-otp/';
  static const String _loginPath = '/api/accounts/v1/login/';

  AuthApi() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Enable detailed logging in debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );

      // Custom logging to show full URI
      _dio.interceptors.add(_CustomLoggingInterceptor());
    }
  }

  /// Send OTP to phone number.
  Future<void> sendOtp({
    required String phone,
    required String role,
  }) async {
    try {
      await _dio.post(
        _sendOtpPath,
        data: {
          'phone': phone,
          'role': role,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP and get session.
  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otpCode,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        _verifyOtpPath,
        data: {
          'phone': phone,
          'otp_code': otpCode,
          'role': role,
        },
      );

      final setCookieHeaders = response.headers[HttpHeaders.setCookieHeader];
      return AuthResponseModel.fromJson(
        response.data,
        setCookieHeaders,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login with username and password.
  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        _loginPath,
        data: {
          'username': username,
          'password': password,
        },
      );

      final setCookieHeaders = response.headers[HttpHeaders.setCookieHeader];
      return AuthResponseModel.fromJson(
        response.data,
        setCookieHeaders,
      );
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

/// Custom logging interceptor to show full URI in logs
class _CustomLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final endpoint = '${options.baseUrl}${options.path}';
      debugPrint('🔵 API REQUEST: ${options.method} $endpoint');
      debugPrint('   Headers: ${options.headers}');
      debugPrint('   Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final endpoint = '${response.requestOptions.baseUrl}${response.requestOptions.path}';
      debugPrint('🟢 API SUCCESS: ${response.statusCode} ${response.requestOptions.method} $endpoint');
      debugPrint('   Response: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final endpoint = '${err.requestOptions.baseUrl}${err.requestOptions.path}';
      debugPrint('🔴 API ERROR: ${err.response?.statusCode} ${err.requestOptions.method} $endpoint');
      debugPrint('   Error: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
