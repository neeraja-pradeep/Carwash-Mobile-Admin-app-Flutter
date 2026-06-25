import 'package:flutter/foundation.dart';

import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../data_sources/reviews_api.dart';

/// Fulfils [ReviewsRepository] from the API (remote-first; errors rethrow so
/// the screen's AsyncValue.error surfaces).
class ReviewsRepositoryImpl implements ReviewsRepository {
  ReviewsRepositoryImpl({ReviewsApi? api}) : _api = api ?? ReviewsApi();

  final ReviewsApi _api;

  @override
  Future<ReviewsPage> fetchReviews({
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
      final response = await _api.getReviews(
        search: search,
        rating: rating,
        shop: shop,
        date: date,
        hasComment: hasComment,
        sort: sort,
        page: page,
        pageSize: pageSize,
      );

      return ReviewsPage(
        reviews: response.results.map((model) => model.toEntity()).toList(),
        count: response.count,
        next: response.next,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching reviews: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Review?> fetchReviewDetail(String id) async {
    try {
      final response = await _api.getReviewDetail(id);
      return response.toEntity();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR fetching review detail: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }
}
