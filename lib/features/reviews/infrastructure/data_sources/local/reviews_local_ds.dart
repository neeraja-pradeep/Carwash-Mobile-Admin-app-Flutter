import '../../../../../app/config/constants.dart';
import '../../../domain/entities/review.dart';

/// Static sample reviews (Alappuzha demo set, from `data.jsx` `REVIEWS`).
///
/// This is the ONLY place review data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class ReviewsLocalDs {
  const ReviewsLocalDs();

  Future<List<Review>> fetchReviews() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _reviews;
  }

  static const List<Review> _reviews = [
    Review(
      id: 'r1',
      rating: 5,
      customer: 'Deepak Nair',
      phone: '+91 94950 27718',
      shop: 'ShineHub Iron Bridge',
      date: '29 May',
      time: '10:42 AM',
      bookingId: 'DD-KL-20260529-0043',
      drivers: ['Anand'],
      text:
          'Excellent service, my car came back spotless. The driver was punctual '
          'and very polite. Will definitely book again.',
    ),
    Review(
      id: 'r2',
      rating: 4,
      customer: 'Anitha Thomas',
      phone: '+91 95440 33871',
      shop: 'GleamPro Vazhicherry',
      date: '29 May',
      time: '1:20 PM',
      bookingId: 'DD-KL-20260529-0046',
      drivers: ['Vishnu'],
      text:
          'Good full detail, interior looks new. Took a little longer than the '
          'estimate but worth it.',
    ),
    Review(
      id: 'r3',
      rating: 5,
      customer: 'Reshma S',
      phone: '+91 90480 55310',
      shop: 'GleamPro Vazhicherry',
      date: '29 May',
      time: '9:35 AM',
      bookingId: 'DD-KL-20260529-0039',
      drivers: ['Vishnu'],
      text: 'Quick and convenient. Loved the doorstep pickup.',
    ),
    Review(
      id: 'r4',
      rating: 3,
      customer: 'Sajan Varghese',
      phone: '+91 99950 71240',
      shop: 'BlueWave Komala Rd',
      date: '28 May',
      time: '5:10 PM',
      bookingId: 'DD-KL-20260528-0017',
      drivers: ['Anand'],
      text:
          "Wash was okay but they missed the underbody I'd paid for. Founder "
          'sorted it out though.',
    ),
    Review(
      id: 'r5',
      rating: 5,
      customer: 'Lakshmi Pillai',
      phone: '+91 90370 64531',
      shop: 'AquaShine Thathampally',
      date: '27 May',
      time: '2:48 PM',
      bookingId: 'DD-KL-20260527-0022',
      drivers: ['Anand'],
      text: '',
    ),
    Review(
      id: 'r6',
      rating: 4,
      customer: 'Priya Menon',
      phone: '+91 98470 11234',
      shop: 'AquaShine Thathampally',
      date: '25 May',
      time: '11:05 AM',
      bookingId: 'DD-KL-20260512-0009',
      drivers: ['Vishnu'],
      text:
          'Reliable and reasonably priced. Booking through the app is smooth.',
    ),
  ];
}
