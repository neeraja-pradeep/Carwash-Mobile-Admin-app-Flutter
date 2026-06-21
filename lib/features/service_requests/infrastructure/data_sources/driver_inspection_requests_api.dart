import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/driver_inspection_request_response_model.dart';
import '../models/driver_inspection_detail_response_model.dart';

class DriverInspectionRequestsApi {
  late Dio _dio;

  static const String _driverInspectionPath =
      '/api/booking/v1/driver-inspection-requests/';

  DriverInspectionRequestsApi() {
    _dio = HttpClient().dio;
  }

  /// Get paginated list of driver/inspection requests with search, filters, and sort.
  Future<DriverInspectionRequestsResponse> getRequests({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? requestType, // 'driver' or 'inspection'
    String? status, // 'new', 'contacted', 'assigned', 'arrived', 'in_progress', 'completed', 'cancelled'
    String? sort, // 'recent', 'upcoming', 'status'
    String? dateRange, // 'today', 'yesterday', 'last_7_days', 'this_month', or custom dates
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      if (requestType != null && requestType.isNotEmpty) {
        params['request_type'] = requestType;
      }

      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      if (sort != null && sort.isNotEmpty) {
        params['sort'] = sort;
      }

      if (dateRange != null && dateRange.isNotEmpty) {
        params['date_range'] = dateRange;
      }

      final response = await _dio.get(
        _driverInspectionPath,
        queryParameters: params,
      );

      return DriverInspectionRequestsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get detail for single request
  Future<DriverInspectionDetailResponse> getDetail(int id) async {
    try {
      final response = await _dio.get('$_driverInspectionPath$id/');
      return DriverInspectionDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get assignable workers for this request
  Future<AssignableWorkersResponse> getAssignableWorkers(
    int id, {
    int? slotId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (slotId != null) {
        params['slot_id'] = slotId;
      }

      final response = await _dio.get(
        '$_driverInspectionPath$id/assignable-workers/',
        queryParameters: params,
      );
      return AssignableWorkersResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Assign worker to request
  Future<ActionResponse> assignWorker({
    required int id,
    required int workerId,
    required int slotId,
    required String workerType, // 'inspector_id' or 'driver_id'
  }) async {
    try {
      final body = {
        workerType: workerId,
        'slot_id': slotId,
      };

      final response = await _dio.post(
        '$_driverInspectionPath$id/assign/',
        data: body,
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update request status
  Future<ActionResponse> updateStatus({
    required int id,
    required String status,
    String? note,
    String? quotedFee,
  }) async {
    try {
      final body = {
        'status': status,
        if (note != null) 'note': note,
        if (quotedFee != null) 'quoted_fee': quotedFee,
      };

      final response = await _dio.post(
        '$_driverInspectionPath$id/status/',
        data: body,
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark request as arrived
  Future<ActionResponse> markArrived(int id) async {
    try {
      final response = await _dio.post(
        '$_driverInspectionPath$id/arrive/',
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify start OTP
  Future<ActionResponse> verifyStartOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    try {
      final body = {
        'otp': otp,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationText != null) 'location_text': locationText,
      };

      final response = await _dio.post(
        '$_driverInspectionPath$id/verify-start-otp/',
        data: body,
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify end OTP
  Future<ActionResponse> verifyEndOtp({
    required int id,
    required String otp,
    double? latitude,
    double? longitude,
    String? locationText,
  }) async {
    try {
      final body = {
        'otp': otp,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationText != null) 'location_text': locationText,
      };

      final response = await _dio.post(
        '$_driverInspectionPath$id/verify-end-otp/',
        data: body,
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel request
  Future<ActionResponse> cancelRequest(int id) async {
    try {
      final response = await _dio.post(
        '$_driverInspectionPath$id/cancel/',
      );

      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
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
      case DioExceptionType.unknown:
        return Exception(e.message ?? 'Unknown error occurred');
    }
  }
}
