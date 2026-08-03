import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/customer_response_model.dart';

class CustomersApi {
  late Dio _dio;

  static const String _customersPath = '/api/accounts/v1/superadmin/customers/';
  static const String _createCustomerPath = '/api/accounts/v1/admin/customers/';
  static const String _addressesPath = '/api/accounts/v1/addresses/';

  CustomersApi() {
    _dio = HttpClient().dio;
  }

  /// Get customers (paginated) with optional search, filter and sort.
  ///
  /// [status]   → `active` | `blocked` (omit for all).
  /// [joined]   → `30d` | `90d` | `year` (`any`/null → no filter).
  /// [bookingCount] → `1-5` | `6-20` | `20plus` (`any`/null → no filter).
  /// [sort]     → `name` | `spend` | `bookings` | `recent`.
  Future<CustomerListResponse> getCustomers({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? joined,
    String? bookingCount,
    String? sort,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (joined != null && joined.isNotEmpty && joined != 'any')
          'joined': joined,
        if (bookingCount != null &&
            bookingCount.isNotEmpty &&
            bookingCount != 'any')
          'booking_count': bookingCount,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
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
    return getCustomers(page: page, pageSize: pageSize, search: query);
  }

  /// Get a single customer's full detail.
  Future<CustomerDetailResponse> getCustomerDetail(String id) async {
    try {
      final response = await _dio.get('$_customersPath$id/');
      return CustomerDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a customer's saved addresses (the ones they added in the customer
  /// app). Paginated by DRF — the `results` array is all we need here.
  Future<List<CustomerAddressModel>> getSavedAddresses(int userId) async {
    try {
      final response = await _dio.get(
        _addressesPath,
        queryParameters: {'user_id': userId},
      );
      final data = response.data;
      final results = data is Map<String, dynamic> ? data['results'] : data;
      return (results as List?)
              ?.cast<Map<String, dynamic>>()
              .map(CustomerAddressModel.fromJson)
              .toList() ??
          const [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update the editable founder notes on a customer.
  Future<CustomerDetailResponse> patchFounderNotes(
    String id,
    String notes,
  ) async {
    try {
      final response = await _dio.patch(
        '$_customersPath$id/',
        data: {'founder_notes': notes},
      );
      return CustomerDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Block a customer. [reason] (enum) and [notes] are both optional.
  Future<CustomerBlockResponse> blockCustomer(
    String id, {
    String? reason,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      final response = await _dio.post(
        '$_customersPath$id/block/',
        data: body,
      );
      return CustomerBlockResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unblock a customer.
  Future<CustomerBlockResponse> unblockCustomer(String id) async {
    try {
      final response = await _dio.post('$_customersPath$id/unblock/');
      return CustomerBlockResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch one page of a customer's merged booking history.
  Future<CustomerHistoryResponse> getCustomerHistory(
    String id, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_customersPath$id/history/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return CustomerHistoryResponse.fromJson(
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
      default:
        return Exception(e.message ?? 'Unknown error occurred');
    }
  }
}
