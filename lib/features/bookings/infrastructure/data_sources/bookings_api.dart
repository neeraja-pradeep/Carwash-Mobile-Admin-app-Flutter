import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/booking_response_model.dart';
import '../models/booking_detail_response_model.dart';
import '../models/refund_response_model.dart';

class BookingsApi {
  late Dio _dio;

  static const String _bookingsPath = '/api/booking/v1/bookings/';

  BookingsApi() {
    _dio = HttpClient().dio;
  }

  /// Get all bookings (paginated) with filters, search, and sort
  Future<BookingListResponse> getBookings({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? dateRange,
    String? timeOfDay,
    List<String>? statusChips,
    List<String>? shops,
    String? assignment,
    String? sort,
  }) async {
    try {
      final params = {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateRange != null && dateRange.isNotEmpty) 'date_range': dateRange,
        if (timeOfDay != null && timeOfDay.isNotEmpty) 'time_of_day': timeOfDay,
        if (assignment != null && assignment.isNotEmpty) 'assignment': assignment,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      // Add repeatable status chips
      if (statusChips != null && statusChips.isNotEmpty) {
        for (final chip in statusChips) {
          params.addAll({'status_chip': chip});
        }
      }

      // Add repeatable shops
      if (shops != null && shops.isNotEmpty) {
        for (final shop in shops) {
          params.addAll({'shop': shop});
        }
      }

      final response = await _dio.get(
        _bookingsPath,
        queryParameters: params,
      );

      return BookingListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get booking detail by ID
  Future<BookingDetailResponse> getBookingDetail(int id) async {
    try {
      final response = await _dio.get('$_bookingsPath$id/');

      return BookingDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get assignable drivers for a booking
  Future<AssignableDriversResponse> getAssignableDrivers(int id) async {
    try {
      final response = await _dio.get('$_bookingsPath$id/assignable-drivers/');

      return AssignableDriversResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Assign a driver to a booking
  Future<void> assignDriver(int bookingId, int driverId) async {
    try {
      await _dio.post(
        '$_bookingsPath$bookingId/assign-driver/',
        data: {'driver_id': driverId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Assign the current user (driver) to a booking
  Future<void> assignMe(int bookingId) async {
    try {
      await _dio.post('$_bookingsPath$bookingId/assign-me/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update booking washing status
  Future<void> updateWashingStatus(int bookingId, String washingStatus) async {
    try {
      await _dio.patch(
        '$_bookingsPath$bookingId/',
        data: {'washing_status': washingStatus},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get damage check report for a booking
  Future<Map<String, dynamic>> getDamageCheck(int bookingId) async {
    try {
      final response = await _dio.get('$_bookingsPath$bookingId/damage-check/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Save damage check report for a booking
  Future<void> saveDamageCheck(
    int bookingId, {
    required String stage,
    required bool checked,
    required String issuesFound,
    List<String>? damageTypes,
    List<String>? panels,
    String? notes,
  }) async {
    try {
      final body = {
        'stage': stage,
        'checked': checked,
        'issues_found': issuesFound,
        if (damageTypes != null) 'damage_types': damageTypes,
        if (panels != null) 'panels': panels,
        if (notes != null) 'notes': notes,
      };

      await _dio.post(
        '$_bookingsPath$bookingId/damage-check/',
        data: body,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel a booking with optional reason
  Future<void> cancelBooking(int bookingId, {String? reason}) async {
    try {
      final body = {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      await _dio.post(
        '$_bookingsPath$bookingId/cancel/',
        data: body.isEmpty ? null : body,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refund a booking
  Future<void> refundBooking(int bookingId, {String? reason}) async {
    try {
      final body = {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      await _dio.post(
        '$_bookingsPath$bookingId/refund/',
        data: body.isEmpty ? null : body,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get refund summary for a carwash booking
  /// Returns: amount_paid, total_refunded, remaining, refunds[]
  Future<RefundSummaryResponse> getRefundSummary(int bookingId) async {
    try {
      final response = await _dio.get(
        '/api/booking/v1/admin/refunds/carwash/$bookingId/',
      );

      return RefundSummaryResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new refund for a carwash booking
  /// Body: { "percent": 100, "reason": "...", "comment": "..." }
  /// OR { "amount": 250, "reason": "...", "comment": "..." }
  Future<RefundResponse> createRefund(
    int bookingId, {
    int? percent,
    int? amount,
    String? reason,
    String? comment,
  }) async {
    try {
      final body = {
        if (percent != null) 'percent': percent,
        if (amount != null) 'amount': amount,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await _dio.post(
        '/api/booking/v1/admin/refunds/carwash/$bookingId/',
        data: body,
      );

      return RefundResponse.fromJson(
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
