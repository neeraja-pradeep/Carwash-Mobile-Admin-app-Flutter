import 'package:new_flutter_project/app/config/constants.dart';

import '../../../domain/entities/activity_item.dart';
import '../../../domain/entities/dashboard_snapshot.dart';
import '../../../domain/entities/hiring_snapshot.dart';

/// Static sample dashboard data (Alappuzha demo set, from `data.jsx`
/// SNAPSHOT 444-451, HIRING_SNAPSHOT 454-459, ACTIVITY 436-442).
///
/// This is the ONLY place dashboard data lives today. In the API phase a remote
/// data source + Hive cache plug in behind the same repository contract — the
/// UI and providers stay unchanged.
class DashboardLocalDs {
  const DashboardLocalDs();

  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _snapshot;
  }

  Future<HiringSnapshot> fetchHiringSnapshot() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _hiringSnapshot;
  }

  Future<List<ActivityItem>> fetchActivityFeed() async {
    await Future<void>.delayed(AppConstants.sampleLoadDelay);
    return _activity;
  }

  static const DashboardSnapshot _snapshot = DashboardSnapshot(
    bookingsToday: 9,
    waiting: 1,
    inProgress: 4,
    doneToday: 3,
    activeNow: 4,
    overdue: 2,
    pendingRefunds: 2,
    pendingRefundAmt: 1450,
  );

  static const HiringSnapshot _hiringSnapshot = HiringSnapshot(
    driversOnline: 3,
    driversTotal: 4,
    onJobNow: 2,
    hireRequestsToday: 3,
    hireOpen: 1,
    inspectionsToday: 2,
    inspectOpen: 1,
  );

  static const List<ActivityItem> _activity = [
    ActivityItem(
      iconKey: 'inbox',
      text: 'New booking from Priya Menon · AquaShine',
      time: '3 min ago',
      bookingId: 'DD-KL-20260529-0048',
    ),
    ActivityItem(
      iconKey: 'droplet',
      text: 'Wash done — Anitha Thomas · GleamPro',
      time: '24 min ago',
      bookingId: 'DD-KL-20260529-0046',
    ),
    ActivityItem(
      iconKey: 'car',
      text: 'Returning to customer — Sajan Varghese',
      time: '55 min ago',
      bookingId: 'DD-KL-20260529-0045',
    ),
    ActivityItem(
      iconKey: 'receipt',
      text: 'Refund issued ₹1,100 — Mohammed Ashraf',
      time: '1 hr ago',
      bookingId: 'DD-KL-20260529-0040',
    ),
    ActivityItem(
      iconKey: 'star',
      text: 'New 5★ review — Deepak Nair · ShineHub',
      time: '2 hr ago',
      bookingId: 'DD-KL-20260529-0043',
    ),
  ];
}
