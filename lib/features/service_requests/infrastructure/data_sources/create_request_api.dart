import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/create_request_response_model.dart';

class CreateRequestApi {
  late Dio _dio;

  static const String _customersPath = '/api/accounts/v1/superadmin/customers/';
  static const String _createCustomerPath = '/api/accounts/v1/admin/customers/';
  static const String _createRequestPath = '/api/booking/v1/admin/manual-di-booking/';

  CreateRequestApi() {
    _dio = HttpClient().dio;
  }

  /// Search existing customers by phone, name, or username
  Future<CustomerListResponse> searchCustomers(String query) async {
    try {
      final params = {'search': query};
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
  /// Returns [CreateCustomerResponse] on success
  /// Throws with 409 error if phone already exists (customer_id included in error)
  Future<CreateCustomerResponse> createCustomer({
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

      return CreateCustomerResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // Check for 409 conflict (customer already exists)
      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        if (errorData != null && errorData.containsKey('customer_id')) {
          final msg = errorData['phone'] as String? ?? 'Customer already exists';
          throw Exception('$msg (customer_id: ${errorData['customer_id']})');
        }
      }
      throw _handleError(e);
    }
  }

  /// Create a new driver hire or inspection request
  Future<CreateRequestResponse> createRequest({
    required int customerId,
    required String requestType, // 'driver' or 'inspection'
    String? tripType, // 'one_way', 'round_trip', 'hourly', 'hospital'
    String? inspectionType, // 'pre_purchase', 'pre_sale'
    String? vehicleText,
    int? carId,
    required String appointmentDate,
    int? startSlot,
    String? startTime,
    String? addressText,
    double? latitude,
    double? longitude,
    String? dropAddressText,
    double? dropLatitude,
    double? dropLongitude,
    String? quotedFee,
    String? customerNote,
    String? hourlyPackage,
    int? requestedHours,
  }) async {
    try {
      final body = {
        'customer_id': customerId,
        'request_type': requestType,
        if (tripType != null) 'trip_type': tripType,
        if (inspectionType != null) 'inspection_type': inspectionType,
        if (vehicleText != null) 'vehicle_text': vehicleText,
        if (carId != null) 'car_id': carId,
        'appointment_date': appointmentDate,
        if (startSlot != null) 'start_slot': startSlot,
        if (startTime != null) 'start_time': startTime,
        if (addressText != null) 'address_text': addressText,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (dropAddressText != null) 'drop_address_text': dropAddressText,
        if (dropLatitude != null) 'drop_latitude': dropLatitude,
        if (dropLongitude != null) 'drop_longitude': dropLongitude,
        if (quotedFee != null) 'quoted_fee': quotedFee,
        if (customerNote != null) 'customer_note': customerNote,
        if (hourlyPackage != null) 'hourly_package': hourlyPackage,
        if (requestedHours != null) 'requested_hours': requestedHours,
      };

      final response = await _dio.post(
        _createRequestPath,
        data: body,
      );

      return CreateRequestResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
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
        if (statusCode == 400 && errorData.isNotEmpty) {
          final errors = <String>[];
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors.add('${key.replaceAll('_', ' ')}: ${value.first}');
            } else if (value is String) {
              errors.add('${key.replaceAll('_', ' ')}: $value');
            }
          });
          if (errors.isNotEmpty) {
            return Exception(errors.join('\n'));
          }
        }

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
