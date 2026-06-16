import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../data_sources/local/bookings_local_ds.dart';

/// Fulfils [BookingsRepository] from the local static data source.
///
/// In the API phase this gains a remote source + cache-check-then-network
/// flow; the contract and callers do not change.
class BookingsRepositoryImpl implements BookingsRepository {
  const BookingsRepositoryImpl(this._local);

  final BookingsLocalDs _local;

  @override
  Future<List<Booking>> fetchBookings() => _local.fetchBookings();
}
