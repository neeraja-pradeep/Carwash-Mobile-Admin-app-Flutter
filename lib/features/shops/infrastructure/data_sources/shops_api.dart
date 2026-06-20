import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/shop_detail_response_model.dart';
import '../models/shop_list_response_model.dart';

class ShopsApi {
  late Dio _dio;

  static const String _shopsPath = '/api/shop/v1/shops/';

  ShopsApi() {
    _dio = HttpClient().dio;
  }

  /// Get paginated list of shops with search, filters, and sort.
  Future<ShopsListResponse> getShops({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? vehicleType,
    double? minRating,
    String? sort,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      if (vehicleType != null && vehicleType.isNotEmpty) {
        params['vehicle_type'] = vehicleType;
      }

      if (minRating != null && minRating > 0) {
        params['min_rating'] = minRating;
      }

      if (sort != null && sort.isNotEmpty) {
        params['sort'] = sort;
      }

      final response = await _dio.get(
        _shopsPath,
        queryParameters: params,
      );

      return ShopsListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get shop detail by ID.
  Future<ShopDetailResponseModel> getShopDetail(String shopId) async {
    try {
      final response = await _dio.get('$_shopsPath$shopId/');
      return ShopDetailResponseModel.fromJson(
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
