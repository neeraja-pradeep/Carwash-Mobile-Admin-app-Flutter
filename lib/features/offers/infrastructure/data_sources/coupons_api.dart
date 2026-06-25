import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/coupon_response_model.dart';

class CouponsApi {
  late Dio _dio;

  static const String _couponsPath = '/api/booking/v1/coupons/';

  CouponsApi() {
    _dio = HttpClient().dio;
  }

  /// List coupons (paginated) with optional search / lifecycle / ordering.
  ///
  /// [lifecycle] is a comma-separated subset of
  /// `active`,`scheduled`,`paused`,`expired`.
  /// [ordering] is `-created_at` (default) or `name`.
  Future<CouponListResponse> getCoupons({
    String? search,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async {
    try {
      final params = {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (lifecycle != null && lifecycle.isNotEmpty) 'lifecycle': lifecycle,
        if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
      };

      final response = await _dio.get(
        _couponsPath,
        queryParameters: params,
      );

      return CouponListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single coupon by id (for the Edit form).
  Future<CouponModel> getCouponDetail(String id) async {
    try {
      final response = await _dio.get('$_couponsPath$id/');
      return CouponModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a coupon. Returns the created coupon (201 read shape).
  Future<CouponModel> createCoupon(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(_couponsPath, data: body);
      return CouponModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Partial-update a coupon. Returns the updated coupon (200 read shape).
  Future<CouponModel> updateCoupon(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch('$_couponsPath$id/', data: body);
      return CouponModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a coupon (204 no content).
  Future<void> deleteCoupon(String id) async {
    try {
      await _dio.delete('$_couponsPath$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and throw appropriate error.
  ///
  /// Surfaces field-keyed 400/409 validation messages (the write serializer
  /// returns `{field: [message]}` maps) so the form can show a useful toast.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 429) {
        return Exception('Too many requests. Please try again later.');
      }

      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        // Prefer the standard error keys.
        final direct = errorData['error'] ??
            errorData['detail'] ??
            errorData['message'];
        if (direct != null) {
          return Exception(direct.toString());
        }

        // Otherwise surface the first field-keyed validation message
        // (400/409 from CouponCreateUpdateSerializer).
        for (final entry in errorData.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return Exception('${entry.key}: ${value.first}');
          }
          if (value is String && value.isNotEmpty) {
            return Exception('${entry.key}: $value');
          }
        }
        return Exception('An error occurred');
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
