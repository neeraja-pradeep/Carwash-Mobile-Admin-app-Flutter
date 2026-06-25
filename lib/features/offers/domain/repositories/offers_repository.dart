import '../entities/coupon.dart';
import '../entities/offer_banner.dart';

/// A page of coupons + the total server count (DRF envelope).
class CouponPage {
  const CouponPage({required this.coupons, required this.count});

  final List<Coupon> coupons;
  final int count;
}

/// Abstract contract — implemented in infrastructure; called from application.
abstract interface class OffersRepository {
  /// Coupons (remote). Filters/sort are applied server-side.
  Future<CouponPage> fetchCoupons({
    String? search,
    String? lifecycle,
    String? ordering,
    int page,
  });

  /// Single coupon by id (for the Edit form).
  Future<Coupon> fetchCouponDetail(String id);

  /// Create a coupon — [body] is the write payload. Returns the created coupon.
  Future<Coupon> createCoupon(Map<String, dynamic> body);

  /// Partial-update a coupon — [body] holds only the changed fields.
  Future<Coupon> updateCoupon(String id, Map<String, dynamic> body);

  /// Delete a coupon.
  Future<void> deleteCoupon(String id);

  /// Banners (local — out of scope for the API integration).
  Future<List<OfferBanner>> fetchBanners();
}
