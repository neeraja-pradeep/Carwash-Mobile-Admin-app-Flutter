import '../entities/review.dart';

/// A page of reviews plus pagination metadata.
class ReviewsPage {
  const ReviewsPage({
    required this.reviews,
    required this.count,
    this.next,
  });

  final List<Review> reviews;

  /// Total number of reviews matching the query (across all pages).
  final int count;

  /// URL of the next page, or `null` when this is the last page.
  final String? next;
}

/// Contract for reading customer reviews. Pure abstract — no implementation.
abstract class ReviewsRepository {
  /// A page of reviews matching the given filters (server-side filtered/sorted).
  ///
  /// `rating`: `any` | `5` | `4` | `3`. `date`: `7d` | `30d` | `all`.
  /// `sort`: `recent` | `rating_desc` | `rating_asc`.
  Future<ReviewsPage> fetchReviews({
    String? search,
    String? rating,
    int? shop,
    String? date,
    bool? hasComment,
    String? sort,
    int page = 1,
    int pageSize = 20,
  });

  /// A single review's full detail, or `null` if it can't be fetched.
  Future<Review?> fetchReviewDetail(String id);
}
