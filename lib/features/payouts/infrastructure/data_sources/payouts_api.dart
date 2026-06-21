import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/payout_response_model.dart';

class PayoutsApi {
  late Dio _dio;

  static const String _basePath = '/api/booking/v1/admin/payouts';

  PayoutsApi() {
    _dio = HttpClient().dio;
  }

  /// Get payout log (all shops, last 90 days by default)
  /// GET /api/booking/v1/admin/payouts/
  Future<PayoutsListResponse> getPayoutLog({
    String? search,
    String? status,
    String? shop,
    String? sort,
    int? days,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (shop != null && shop.isNotEmpty) {
        queryParams['shop'] = shop;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }
      if (days != null && days > 0) {
        queryParams['days'] = days;
      }

      final response = await _dio.get(
        _basePath,
        queryParameters: queryParams,
      );

      return PayoutsListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DIO errors and convert to user-friendly messages
  Exception _handleError(DioException e) {
    String message = 'Error fetching payout log';

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 400) {
        message = (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : 'Invalid filter parameters';
      } else if (statusCode == 403) {
        message = 'You do not have permission to access payouts';
      } else if (statusCode == 404) {
        message = 'Payouts not found';
      } else if (statusCode == 500) {
        message = 'Server error. Please try again.';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your network.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout. Please try again.';
    }

    return Exception(message);
  }
}
