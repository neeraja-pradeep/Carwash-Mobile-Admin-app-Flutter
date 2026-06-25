import 'package:new_flutter_project/app/config/constants.dart';

import '../../../domain/entities/offer_banner.dart';

const Duration kSampleLoadDelay = AppConstants.sampleLoadDelay;

/// Static sample data for offers — **banners only**.
///
/// Coupons are served from the API ([CouponsApi]); banners remain on local
/// demo data (out of scope for the API integration).
class OffersLocalDs {
  const OffersLocalDs();

  Future<List<OfferBanner>> fetchBanners() async {
    await Future<void>.delayed(kSampleLoadDelay);
    return _banners;
  }

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
