import '../entities/coupon.dart';
import '../entities/offer_banner.dart';

/// A page of coupons + the total server count (DRF envelope).
class CouponPage {
  const CouponPage({required this.coupons, required this.count});

  final List<Coupon> coupons;
  final int count;
}

/// A page of banners + the total server count (DRF envelope).
class BannerPage {
  const BannerPage({required this.banners, required this.count});

  final List<OfferBanner> banners;
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

  /// Banners (remote). Search / filter / sort are applied server-side.
  Future<BannerPage> fetchBanners({
    String? search,
    String? placement,
    String? lifecycle,
    String? ordering,
    int page,
  });

  /// Single banner by id (for the Edit form).
  Future<OfferBanner> fetchBannerDetail(String id);

  /// Create a banner. [imagePath] is a local file uploaded as the artwork.
  Future<OfferBanner> createBanner(
    Map<String, dynamic> body, {
    String? imagePath,
  });

  /// Partial-update a banner. Pass [imagePath] to replace the artwork or
  /// [removeImage] to clear it; pass neither to leave it untouched.
  Future<OfferBanner> updateBanner(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage,
  });

  /// Delete a banner (also removes its CDN image).
  Future<void> deleteBanner(String id);
}
