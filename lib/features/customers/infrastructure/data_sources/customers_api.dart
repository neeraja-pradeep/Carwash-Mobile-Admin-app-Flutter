import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/customer_response_model.dart';

class CustomersApi {
  late Dio _dio;

  static const String _customersPath = '/api/accounts/v1/superadmin/customers/';
  static const String _createCustomerPath = '/api/accounts/v1/admin/customers/';

  CustomersApi() {
    _dio = HttpClient().dio;
  }

  /// Get all customers (paginated)
  Future<CustomerListResponse> getCustomers({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = {
        'page': page,
        'page_size': pageSize,
      };

      final response = await _dio.get(
        _customersPath,
        queryParameters: params,
      );

      return CustomerListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search customers by phone, name, or username
  Future<CustomerListResponse> searchCustomers(
    String query, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = {
        'search': query,
        'page': page,
        'page_size': pageSize,
      };

      final response = await _dio.get(
        _customersPath,
        queryParameters: params,
      );

      return CustomerListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new customer account
  /// Returns [CustomerApiModel] on success (201)
  /// Throws with 409 error if phone already exists (customer_id included in error)
  /// Throws with 400 for validation errors (missing phone/name or bad OTP)
  Future<CustomerApiModel> createCustomer({
    required String phone,
    required String fullName,
    String? otpCode,
    String? email,
  }) async {
    try {
      final body = {
        'phone': phone,
        'full_name': fullName,
        if (otpCode != null) 'otp_code': otpCode,
        if (email != null) 'email': email,
      };

      final response = await _dio.post(
        _createCustomerPath,
        data: body,
      );

      return CustomerApiModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // Check for 409 conflict (customer already exists)
      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        if (errorData != null && errorData.containsKey('customer_id')) {
          final msg = errorData['phone'] as String? ?? 'Customer already exists';
          throw Exception('$msg (ID: ${errorData['customer_id']})');
        }
      }
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error
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
