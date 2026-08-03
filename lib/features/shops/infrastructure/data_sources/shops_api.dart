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

  /// Create a new shop - POST /api/shop/v1/shops/
  Future<ShopDetailResponseModel> createShop(ShopCreateRequest request) async {
    try {
      final response = await _dio.post(
        _shopsPath,
        data: request.toJson(),
      );

      return ShopDetailResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing shop — PATCH /api/shop/v1/shops/{id}/
  ///
  /// Partial by design: only the keys present in [request] are sent, so a field
  /// the form does not manage keeps its stored value.
  Future<ShopDetailResponseModel> updateShop(
    String shopId,
    ShopUpdateRequest request,
  ) async {
    try {
      final response = await _dio.patch(
        '$_shopsPath$shopId/',
        data: request.toJson(),
      );

      return ShopDetailResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Uploads/replaces one photo slot — PATCH /api/shop/v1/shops/{id}/ as
  /// `multipart/form-data` with a single field named [slot] (one of
  /// `cover_image`, `normal_image1`..`normal_image4`). Exactly one of
  /// [filePath] (device file, from the picker) or [bytes] (already-downloaded
  /// data, used when copying a photo onto a duplicated shop) must be given.
  Future<ShopDetailResponseModel> uploadShopPhoto(
    String shopId,
    String slot, {
    String? filePath,
    List<int>? bytes,
  }) async {
    assert(
      (filePath == null) != (bytes == null),
      'Pass exactly one of filePath or bytes.',
    );
    try {
      final file = filePath != null
          ? await MultipartFile.fromFile(filePath)
          : MultipartFile.fromBytes(bytes!, filename: slot);
      final response = await _dio.patch(
        '$_shopsPath$shopId/',
        data: FormData.fromMap({slot: file}),
      );

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
        // Handle validation errors with field-specific messages
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
