import 'package:new_flutter_project/app/config/constants.dart';

import '../../../domain/entities/coupon.dart';
import '../../../domain/entities/offer_banner.dart';

const Duration kSampleLoadDelay = AppConstants.sampleLoadDelay;

/// Static sample data for offers (Alappuzha demo set, from `data.jsx`).
class OffersLocalDs {
  const OffersLocalDs();

  Future<List<Coupon>> fetchCoupons() async {
    await Future<void>.delayed(kSampleLoadDelay);
    return _coupons;
  }

  Future<List<OfferBanner>> fetchBanners() async {
    await Future<void>.delayed(kSampleLoadDelay);
    return _banners;
  }

  static const List<Coupon> _coupons = [
    Coupon(
      id: 'cp1',
      code: 'FIRST50',
      type: 'percentage',
      value: 50,
      maxDiscount: 150,
      minOrder: 300,
      status: 'active',
      scope: 'All shops',
      usageLimit: 500,
      usedCount: 142,
      perUser: 1,
      validFrom: '01-May-2026',
      validTo: '30-Jun-2026',
      description: '50% off first wash for new customers',
    ),
    Coupon(
      id: 'cp2',
      code: 'MONSOON100',
      type: 'flat',
      value: 100,
      minOrder: 500,
      status: 'active',
      scope: 'All shops',
      usageLimit: 500,
      usedCount: 88,
      perUser: 2,
      validFrom: '01-Jun-2026',
      validTo: '31-Jul-2026',
      description: '₹100 off during monsoon season',
    ),
    Coupon(
      id: 'cp3',
      code: 'SPARKLE20',
      type: 'percentage',
      value: 20,
      maxDiscount: 200,
      minOrder: 0,
      status: 'active',
      scope: 'SparkleWash Mullackal',
      usageLimit: 200,
      usedCount: 35,
      perUser: 3,
      validFrom: '15-May-2026',
      validTo: '15-Jun-2026',
      description: '20% off at SparkleWash',
    ),
    Coupon(
      id: 'cp4',
      code: 'WELCOME25',
      type: 'percentage',
      value: 25,
      maxDiscount: 100,
      minOrder: 250,
      status: 'scheduled',
      scope: 'All shops',
      usageLimit: 1000,
      usedCount: 0,
      perUser: 1,
      validFrom: '10-Jun-2026',
      validTo: '10-Jul-2026',
      description: 'Welcome offer launching next week',
    ),
    Coupon(
      id: 'cp5',
      code: 'FLAT75',
      type: 'flat',
      value: 75,
      minOrder: 400,
      status: 'expired',
      scope: 'All shops',
      usageLimit: 300,
      usedCount: 300,
      perUser: 1,
      validFrom: '01-Apr-2026',
      validTo: '30-Apr-2026',
      description: '₹75 off — April promo (ended)',
    ),
    Coupon(
      id: 'cp6',
      code: 'GLEAM15',
      type: 'percentage',
      value: 15,
      maxDiscount: 120,
      minOrder: 0,
      status: 'paused',
      scope: 'GleamPro Vazhicherry',
      usageLimit: 150,
      usedCount: 22,
      perUser: 5,
      validFrom: '01-May-2026',
      validTo: '31-Aug-2026',
      description: '15% off at GleamPro — paused',
    ),
  ];

  static const List<OfferBanner> _banners = [
    OfferBanner(
      id: 'bn1',
      title: 'Up to 40% Off Premium Wash',
      subtitle: 'Limited-time monsoon deal',
      status: 'active',
      placement: 'Home — Hero',
      link: 'Coupon: MONSOON100',
      order: 1,
      image: 'assets/offer-banner.jpg',
      start: '01-Jun-2026',
      end: '31-Jul-2026',
      impressions: 3240,
      taps: 412,
    ),
    OfferBanner(
      id: 'bn2',
      title: 'Doorstep Detailing',
      subtitle: 'Showroom shine, at your home',
      status: 'active',
      placement: 'Home — Hero',
      link: 'Service: Full Detail',
      order: 2,
      image: 'assets/shop-hero.jpg',
      start: '15-May-2026',
      end: '15-Jul-2026',
      impressions: 2110,
      taps: 188,
    ),
    OfferBanner(
      id: 'bn3',
      title: 'Refer & Earn ₹100',
      subtitle: 'Invite friends, both get rewarded',
      status: 'scheduled',
      placement: 'Home — Strip',
      link: 'Screen: Referrals',
      order: 3,
      image: 'assets/offer-banner.jpg',
      start: '10-Jun-2026',
      end: '10-Aug-2026',
      impressions: 0,
      taps: 0,
    ),
    OfferBanner(
      id: 'bn4',
      title: 'First Wash 50% Off',
      subtitle: 'New customers only',
      status: 'inactive',
      placement: 'Home — Hero',
      link: 'Coupon: FIRST50',
      order: 4,
      image: 'assets/shop-thumb.jpg',
      start: '01-Apr-2026',
      end: '—',
      impressions: 5680,
      taps: 901,
    ),
  ];
}
