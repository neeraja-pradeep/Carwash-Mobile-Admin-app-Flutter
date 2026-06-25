import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../models/reviews_response_model.dart';

class ReviewsApi {
  late Dio _dio;

  static const String _reviewsPath = '/api/shop/v1/admin/reviews/';

  ReviewsApi() {
    _dio = HttpClient().dio;
  }

  /// Get reviews (paginated) with optional filters.
  ///
  /// NOTE: the API defaults `date` to `7d`; callers must pass the window the UI
  /// selects (send `date=all` for full history).
  Future<ReviewsPageResponse> getReviews({
    String? search,
    String? rating,
    int? shop,
    String? date,
    bool? hasComment,
    String? sort,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (rating != null && rating.isNotEmpty) 'rating': rating,
        if (shop != null) 'shop': shop,
        if (date != null && date.isNotEmpty) 'date': date,
        if (hasComment != null && hasComment) 'has_comment': hasComment,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      final response = await _dio.get(
        _reviewsPath,
        queryParameters: params,
      );

      return ReviewsPageResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get review detail by ID.
  Future<ReviewDetailModel> getReviewDetail(String id) async {
    try {
      final response = await _dio.get('$_reviewsPath$id/');

      return ReviewDetailModel.fromJson(
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
