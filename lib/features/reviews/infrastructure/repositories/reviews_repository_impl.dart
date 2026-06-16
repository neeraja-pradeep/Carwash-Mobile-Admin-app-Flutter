import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../data_sources/local/reviews_local_ds.dart';

/// Fulfils [ReviewsRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network flow;
/// the contract and callers do not change.
class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._local);

  final ReviewsLocalDs _local;

  @override
  Future<List<Review>> fetchReviews() => _local.fetchReviews();
}
