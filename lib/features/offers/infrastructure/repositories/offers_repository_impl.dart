import 'package:flutter/foundation.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../../domain/repositories/offers_repository.dart';
import '../data_sources/coupons_api.dart';
import '../data_sources/promotions_api.dart';

/// Fulfils [OffersRepository] — coupons from `/coupons/`, banners from
/// `/promotions/`. Both are API-only; errors propagate to the presentation
/// layer rather than falling back to sample data.
class OffersRepositoryImpl implements OffersRepository {
  OffersRepositoryImpl({CouponsApi? api, PromotionsApi? promotions})
      : _api = api ?? CouponsApi(),
        _promotions = promotions ?? PromotionsApi();

  final CouponsApi _api;
  final PromotionsApi _promotions;

  @override
  Future<CouponPage> fetchCoupons({
    String? search,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async {
    try {
      final response = await _api.getCoupons(
        search: search,
        lifecycle: lifecycle,
        ordering: ordering,
        page: page,
      );
      return CouponPage(
        coupons: response.results.map((m) => m.toEntity()).toList(),
        count: response.count,
      );
    } catch (e, st) {
      debugPrint('❌ ERROR fetching coupons: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<Coupon> fetchCouponDetail(String id) async {
    try {
      final model = await _api.getCouponDetail(id);
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR fetching coupon detail: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<Coupon> createCoupon(Map<String, dynamic> body) async {
    try {
      final model = await _api.createCoupon(body);
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR creating coupon: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<Coupon> updateCoupon(String id, Map<String, dynamic> body) async {
    try {
      final model = await _api.updateCoupon(id, body);
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR updating coupon: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<void> deleteCoupon(String id) async {
    try {
      await _api.deleteCoupon(id);
    } catch (e, st) {
      debugPrint('❌ ERROR deleting coupon: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<BannerPage> fetchBanners({
    String? search,
    String? placement,
    String? lifecycle,
    String? ordering,
    int page = 1,
  }) async {
    try {
      final response = await _promotions.getPromotions(
        search: search,
        placement: placement,
        lifecycle: lifecycle,
        ordering: ordering,
        page: page,
      );
      return BannerPage(
        banners: response.results.map((m) => m.toEntity()).toList(),
        count: response.count,
      );
    } catch (e, st) {
      debugPrint('❌ ERROR fetching banners: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<OfferBanner> fetchBannerDetail(String id) async {
    try {
      final model = await _promotions.getPromotionDetail(id);
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR fetching banner detail: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<OfferBanner> createBanner(
    Map<String, dynamic> body, {
    String? imagePath,
  }) async {
    try {
      final model = await _promotions.createPromotion(
        body,
        imagePath: imagePath,
      );
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR creating banner: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<OfferBanner> updateBanner(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      final model = await _promotions.updatePromotion(
        id,
        body,
        imagePath: imagePath,
        removeImage: removeImage,
      );
      return model.toEntity();
    } catch (e, st) {
      debugPrint('❌ ERROR updating banner: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<void> deleteBanner(String id) async {
    try {
      await _promotions.deletePromotion(id);
    } catch (e, st) {
      debugPrint('❌ ERROR deleting banner: $e');
      debugPrint('StackTrace: $st');
      rethrow;
    }
  }
}
