import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/refund_response_model.dart';

class RefundsApi {
  late Dio _dio;

  static const String _refundsPath = '/api/booking/v1/admin/refunds/';

  RefundsApi() {
    _dio = HttpClient().dio;
  }

  /// Get all refunds (paginated) with optional filters
  Future<RefundListResponse> getRefunds({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? reason,
    String? sort,
  }) async {
    try {
      final params = {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      final response = await _dio.get(
        _refundsPath,
        queryParameters: params,
      );

      return RefundListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get refund detail by ID
  Future<RefundDetailResponse> getRefundDetail(String id) async {
    try {
      final response = await _dio.get('$_refundsPath$id/');

      return RefundDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get list response model (used for parsing paginated responses)
  RefundListResponse parseListResponse(Map<String, dynamic> data) {
    return RefundListResponse.fromJson(data);
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
