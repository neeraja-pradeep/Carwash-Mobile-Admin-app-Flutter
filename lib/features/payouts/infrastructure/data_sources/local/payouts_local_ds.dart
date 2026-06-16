import 'package:new_flutter_project/app/config/constants.dart';
import '../../../domain/entities/payout.dart';

/// Static sample payouts from data.jsx PAYOUTS (lines 574–602).
class PayoutsLocalDs {
  const PayoutsLocalDs();

  Future<List<Payout>> fetchPayouts() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _payouts;
  }

  static const List<Payout> _payouts = [
    Payout(
      id: 'PO-20260529-007',
      shopId: 's1',
      period: '1 May – 29 May 2026',
      status: 'pending',
      createdAt: '29 May, 5:30 PM',
      paidAt: null,
      utr: '',
      proof: false,
      adjustments: [],
      bookings: [
        PayoutBooking(
          date: '26 May',
          id: 'DD-KL-20260526-0031',
          customer: 'Faisal R.',
          gross: 650,
          commission: 98,
          refund: 0,
          excluded: false,
        ),
        PayoutBooking(
          date: '27 May',
          id: 'DD-KL-20260527-0019',
          customer: 'Reshma S.',
          gross: 500,
          commission: 75,
          refund: 0,
          excluded: false,
        ),
        PayoutBooking(
          date: '28 May',
          id: 'DD-KL-20260528-0024',
          customer: 'Lakshmi P.',
          gross: 670,
          commission: 101,
          refund: 150,
          excluded: false,
        ),
        PayoutBooking(
          date: '29 May',
          id: 'DD-KL-20260529-0042',
          customer: 'Ramesh K.',
          gross: 500,
          commission: 75,
          refund: 0,
          excluded: false,
        ),
      ],
    ),
    Payout(
      id: 'PO-20260520-006',
      shopId: 's2',
      period: '10 May – 20 May 2026',
      status: 'paid',
      createdAt: '20 May, 6:10 PM',
      paidAt: '20 May, 8:45 PM',
      utr: 'UPI/SBIN/552011900',
      proof: true,
      adjustments: [],
      bookings: [
        PayoutBooking(
          date: '12 May',
          id: 'DD-KL-20260512-0009',
          customer: 'Priya M.',
          gross: 250,
          commission: 40,
          refund: 0,
          excluded: false,
        ),
        PayoutBooking(
          date: '16 May',
          id: 'DD-KL-20260516-0014',
          customer: 'Anil V.',
          gross: 300,
          commission: 40,
          refund: 0,
          excluded: false,
        ),
      ],
    ),
    Payout(
      id: 'PO-20260524-005',
      shopId: 's3',
      period: '15 May – 24 May 2026',
      status: 'paid',
      createdAt: '24 May, 7:00 PM',
      paidAt: '24 May, 9:15 PM',
      utr: 'UPI/ICIC/774120091',
      proof: true,
      adjustments: [
        PayoutAdjustment(
          amount: -120,
          reason: 'Towel restock shared cost',
          at: '24 May',
        ),
      ],
      bookings: [
        PayoutBooking(
          date: '18 May',
          id: 'DD-KL-20260518-0020',
          customer: 'Meera J.',
          gross: 950,
          commission: 142,
          refund: 0,
          excluded: false,
        ),
        PayoutBooking(
          date: '22 May',
          id: 'DD-KL-20260522-0027',
          customer: 'Tom K.',
          gross: 500,
          commission: 75,
          refund: 0,
          excluded: false,
        ),
      ],
    ),
  ];
}
