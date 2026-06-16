import '../entities/review.dart';

/// Contract for reading customer reviews. Pure abstract — no implementation.
abstract class ReviewsRepository {
  /// All reviews, newest first.
  Future<List<Review>> fetchReviews();
}
