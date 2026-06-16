import 'package:new_flutter_project/app/config/constants.dart';
import '../../../domain/entities/refund.dart';

/// Static sample refunds from data.jsx REFUNDS (lines 565–571).
class RefundsLocalDs {
  const RefundsLocalDs();

  Future<List<Refund>> fetchRefunds() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _refunds;
  }

  static const List<Refund> _refunds = [
    Refund(
      id: 'RF-20260529-014',
      amount: 1100,
      status: 'requested',
      bookingId: 'DD-KL-20260529-0040',
      customer: RefundCustomer(
        name: 'Mohammed Ashraf',
        phone: '+91 98951 40023',
      ),
      tier: '100%',
      reason: 'Cancellation by customer',
      notes: 'Cancelled before assignment — full refund per tier.',
      createdAt: '29 May, 8:25 AM',
      approvedAt: null,
      paidAt: null,
      utr: '',
      proof: false,
    ),
    Refund(
      id: 'RF-20260528-013',
      amount: 320,
      status: 'approved',
      bookingId: 'DD-KL-20260528-0017',
      customer: RefundCustomer(
        name: 'Sajan Varghese',
        phone: '+91 99950 71240',
      ),
      tier: 'Override',
      reason: 'Service quality issue',
      notes: 'Underbody wash missed — goodwill refund.',
      createdAt: '28 May, 5:30 PM',
      approvedAt: '28 May, 6:02 PM',
      paidAt: null,
      utr: '',
      proof: false,
    ),
    Refund(
      id: 'RF-20260528-012',
      amount: 455,
      status: 'paid',
      bookingId: 'DD-KL-20260528-0011',
      customer: RefundCustomer(
        name: 'Priya Menon',
        phone: '+91 98470 11234',
      ),
      tier: '70%',
      reason: 'Cancellation by customer',
      notes: 'Cancelled after assignment, before pickup.',
      createdAt: '28 May, 11:10 AM',
      approvedAt: '28 May, 11:24 AM',
      paidAt: '28 May, 12:40 PM',
      utr: 'UPI/AXIS/552210034',
      proof: true,
    ),
    Refund(
      id: 'RF-20260527-011',
      amount: 250,
      status: 'declined',
      bookingId: 'DD-KL-20260527-0008',
      customer: RefundCustomer(
        name: 'Deepak Nair',
        phone: '+91 94950 27718',
      ),
      tier: '0%',
      reason: 'Cancellation by customer',
      notes: 'Cancelled post-pickup — no refund per policy.',
      createdAt: '27 May, 2:15 PM',
      approvedAt: null,
      paidAt: null,
      utr: '',
      proof: false,
    ),
    Refund(
      id: 'RF-20260526-010',
      amount: 900,
      status: 'paid',
      bookingId: 'DD-KL-20260526-0004',
      customer: RefundCustomer(
        name: 'Anitha Thomas',
        phone: '+91 95440 33871',
      ),
      tier: '100%',
      reason: 'Damage during wash',
      notes: 'Minor scratch — full refund + apology.',
      createdAt: '26 May, 4:50 PM',
      approvedAt: '26 May, 5:05 PM',
      paidAt: '26 May, 7:20 PM',
      utr: 'UPI/HDFC/889201144',
      proof: true,
    ),
  ];
}
