import '../../../../../app/config/constants.dart';
import '../../../domain/entities/app_notification.dart';

/// Static sample notifications (from `data.jsx` NOTIFICATIONS, lines 699–707).
///
/// This is the sole data source in the static prototype.
class NotificationsLocalDs {
  const NotificationsLocalDs();

  Future<List<AppNotification>> fetchNotifications() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _notifications;
  }

  static const List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.booking,
      title: 'New booking received',
      body: 'Priya Menon · AquaShine Thathampally · 4:15 PM pickup',
      time: '3 min ago',
      unread: true,
      bookingId: 'DD-KL-20260529-0048',
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.overdue,
      title: 'Booking unassigned',
      body: "Priya Menon's booking has no driver 18 min after slot start",
      time: '12 min ago',
      unread: true,
      bookingId: 'DD-KL-20260529-0048',
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.wash,
      title: 'Wash completed',
      body: 'Anitha Thomas · GleamPro Vazhicherry — ready for drop',
      time: '24 min ago',
      unread: true,
      bookingId: 'DD-KL-20260529-0046',
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.refund,
      title: 'Refund requested',
      body: 'Mohammed Ashraf · ₹1,100 · awaiting your approval',
      time: '1 hr ago',
      unread: false,
      refundId: 'RF-20260529-014',
    ),
    AppNotification(
      id: 'n5',
      kind: NotificationKind.review,
      title: 'New 5★ review',
      body: 'Deepak Nair rated ShineHub Iron Bridge',
      time: '2 hr ago',
      unread: false,
      reviewId: 'r1',
    ),
    AppNotification(
      id: 'n6',
      kind: NotificationKind.payout,
      title: 'Payout marked paid',
      body: 'AquaShine Thathampally · ₹3,920 · UTR logged',
      time: 'Yesterday',
      unread: false,
      payoutId: 'PO-20260520-006',
    ),
    AppNotification(
      id: 'n7',
      kind: NotificationKind.holiday,
      title: 'Holiday reminder',
      body: 'Local festival on Sun 07 Jun affects 4 shops',
      time: 'Yesterday',
      unread: false,
    ),
  ];
}
