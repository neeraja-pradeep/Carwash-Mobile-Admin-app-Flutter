import 'package:flutter/foundation.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/entities/offer_banner.dart';
import '../../domain/repositories/offers_repository.dart';
import '../data_sources/coupons_api.dart';
import '../data_sources/local/offers_local_ds.dart';

/// Fulfils [OffersRepository] — coupons from the API, banners from local data.
class OffersRepositoryImpl implements OffersRepository {
  OffersRepositoryImpl(this._local, {CouponsApi? api})
      : _api = api ?? CouponsApi();

  final OffersLocalDs _local;
  final CouponsApi _api;

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
  Future<List<OfferBanner>> fetchBanners() => _local.fetchBanners();
}
