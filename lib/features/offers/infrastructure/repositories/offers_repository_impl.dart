import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../../domain/repositories/offers_repository.dart';
import '../data_sources/local/offers_local_ds.dart';

/// Fulfils [OffersRepository] from the local static data source.
class OffersRepositoryImpl implements OffersRepository {
  const OffersRepositoryImpl(this._local);

  final OffersLocalDs _local;

  @override
  Future<List<Coupon>> fetchCoupons() => _local.fetchCoupons();

  @override
  Future<List<OfferBanner>> fetchBanners() => _local.fetchBanners();
}
