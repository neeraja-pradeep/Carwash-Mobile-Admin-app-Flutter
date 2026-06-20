import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/auth_response_model.dart';

class AuthApi {
  late Dio _dio;

  static const String _sendOtpPath = '/api/accounts/v1/send-otp/';
  static const String _verifyOtpPath = '/api/accounts/v1/verify-otp/';
  static const String _loginPath = '/api/accounts/v1/login/';
  static const String _logoutPath = '/api/accounts/v1/logout/';

  AuthApi() {
    // Use shared HTTP client to maintain session cookies across the app
    _dio = HttpClient().dio;
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
      final authResponse = AuthResponseModel.fromJson(
        response.data,
        setCookieHeaders,
      );

      // Extract and store sessionid for subsequent requests
      if (authResponse.sessionId != null && authResponse.sessionId!.isNotEmpty) {
        HttpClient.setSessionId(authResponse.sessionId!);
      }

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    try {
      await _dio.post(_logoutPath);
      // Clear session ID after successful logout
      HttpClient.clearSessionId();
    } on DioException catch (e) {
      // Clear session ID even if logout fails
      HttpClient.clearSessionId();
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 429) {
        return Exception('Too many login attempts. Please try again later.');
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
