import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../infrastructure/data_sources/dashboard_api.dart';
import '../../infrastructure/models/dashboard_response_model.dart';
import '../../infrastructure/repositories/dashboard_repository_impl.dart';
import '../../../drivers/application/providers/drivers_providers.dart';

/// API data source provider.
final dashboardApiProvider = Provider<DashboardApi>(
  (ref) => DashboardApi(),
);

/// The dashboard repository (domain contract → infrastructure impl with API).
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(),
);

/// Raw dashboard response from API (reused for snapshot and hiring data).
/// This is the ONLY place we call the dashboard API to avoid duplicate requests.
/// autoDispose — refetched whenever the dashboard screen is (re)entered.
final _dashboardResponseProvider = FutureProvider.autoDispose<DashboardResponseModel>(
  (ref) async {
    final api = ref.watch(dashboardApiProvider);
    return api.getDashboardSnapshot();
  },
);

/// Carwash operational snapshot for today.
final dashboardSnapshotProvider = FutureProvider.autoDispose<DashboardSnapshot>(
  (ref) async {
    final response = await ref.watch(_dashboardResponseProvider.future);
    return response.toDomain();
  },
);

/// Roster size for the "Drivers Online" denominator.
///
/// The dashboard endpoint's `drivers_online.total` drops offline drivers from
/// the denominator as well as the numerator, so the card can only ever read
/// N/N ("everyone is online"). Counting the unfiltered roster gives an honest
/// denominator. Returns `null` on failure so the card falls back to the
/// server's value instead of rendering a hole.
final driverRosterCountProvider = FutureProvider.autoDispose<int?>(
  (ref) async {
    try {
      final drivers =
          await ref.watch(driversRepositoryProvider).fetchFieldDrivers();
      return drivers.length;
    } catch (_) {
      return null;
    }
  },
);

/// Driver hiring & inspection snapshot - REUSES dashboard response.
/// Does NOT make a second API call for the snapshot itself; the denominator
/// correction above is a separate, failure-tolerant fetch.
final hiringSnapshotProvider = FutureProvider.autoDispose<HiringSnapshot>(
  (ref) async {
    final response = await ref.watch(_dashboardResponseProvider.future);
    final snapshot = response.driverInspector.toHiringSnapshot();

    final rosterCount = await ref.watch(driverRosterCountProvider.future);
    if (rosterCount == null || rosterCount < snapshot.driversOnline) {
      return snapshot;
    }
    return snapshot.copyWith(driversTotal: rosterCount);
  },
);

/// Recent activity feed (5 items).
final activityFeedProvider = FutureProvider.autoDispose<List<ActivityItem>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchActivityFeed(),
);

/// Unread notification count.
final notificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(dashboardApiProvider).getNotificationCount();
  } catch (e) {
    return 0;
  }
});

/// Refetches every dashboard endpoint.
///
/// [dashboardSnapshotProvider] and [hiringSnapshotProvider] only *derive* from
/// [_dashboardResponseProvider], so invalidating them alone re-reads the cached
/// API response without hitting the network. Callers must go through this
/// helper — it lives in this library so it can reach the private provider.
Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(_dashboardResponseProvider);
  ref.invalidate(driverRosterCountProvider);
  ref.invalidate(activityFeedProvider);
  ref.invalidate(notificationCountProvider);
  await ref.read(dashboardSnapshotProvider.future);
}
