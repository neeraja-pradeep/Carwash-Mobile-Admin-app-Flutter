import '../entities/coupon.dart';
import '../entities/offer_banner.dart';

/// Abstract contract — implemented in infrastructure; called from application.
abstract interface class OffersRepository {
  Future<List<Coupon>> fetchCoupons();
  Future<List<OfferBanner>> fetchBanners();
}
