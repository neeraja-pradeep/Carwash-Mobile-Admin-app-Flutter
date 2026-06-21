import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/shop_service_response_model.dart';

class ShopServicesApi {
  late Dio _dio;

  static const String _basePath = '/api/shop/v1/shop-services/';

  ShopServicesApi() {
    _dio = HttpClient().dio;
  }

  /// List services for a shop: GET /api/shop/v1/shop-services/?shop={id}
  Future<ShopServicesListResponse> getServices(String shopId) async {
    try {
      final response = await _dio.get(
        _basePath,
        queryParameters: {'shop': shopId},
      );
      return ShopServicesListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create service: POST /api/shop/v1/shop-services/
  Future<ShopServiceResponse> createService(
    ShopServiceCreateRequest request,
  ) async {
    try {
      final response = await _dio.post(
        _basePath,
        data: request.toJson(),
      );
      return ShopServiceResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update service: PATCH /api/shop/v1/shop-services/{id}/
  Future<ShopServiceResponse> updateService(
    int serviceId,
    ShopServiceCreateRequest request,
  ) async {
    try {
      final response = await _dio.patch(
        '$_basePath$serviceId/',
        data: request.toJson(),
      );
      return ShopServiceResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Toggle service active: PATCH /api/shop/v1/shop-services/{id}/ with { "active": bool }
  Future<ShopServiceResponse> toggleService(int serviceId, bool active) async {
    try {
      final response = await _dio.patch(
        '$_basePath$serviceId/',
        data: {'active': active},
      );
      return ShopServiceResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Copy services from another shop: POST /api/shop/v1/shop-services/copy-from/
  Future<Map<String, dynamic>> copyServices(
    int sourceShopId,
    int targetShopId,
  ) async {
    try {
      final response = await _dio.post(
        '${_basePath}copy-from/',
        data: {
          'source_shop': sourceShopId,
          'target_shop': targetShopId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Apply price change to all services: POST /api/shop/v1/shop-services/apply-price-change/
  /// percent: e.g. 10 for +10%, -5 for -5%
  Future<Map<String, dynamic>> applyPriceChange(
    int shopId,
    double percent,
  ) async {
    try {
      final response = await _dio.post(
        '${_basePath}apply-price-change/',
        data: {
          'shop': shopId,
          'percent': percent,
        },
      );
      return response.data as Map<String, dynamic>;
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
