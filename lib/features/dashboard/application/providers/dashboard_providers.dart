import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../infrastructure/data_sources/dashboard_api.dart';
import '../../infrastructure/models/dashboard_response_model.dart';
import '../../infrastructure/repositories/dashboard_repository_impl.dart';

/// API data source provider.
final dashboardApiProvider = Provider<DashboardApi>(
  (ref) => DashboardApi(),
);

/// The dashboard repository (domain contract → infrastructure impl with API).
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(),
);

/// Raw dashboard response from API (cached, reused for snapshot and hiring data).
/// This is the ONLY place we call the dashboard API to avoid duplicate requests.
final _dashboardResponseProvider = FutureProvider<DashboardResponseModel>(
  (ref) async {
    final api = ref.watch(dashboardApiProvider);
    return api.getDashboardSnapshot();
  },
);

/// Carwash operational snapshot for today.
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>(
  (ref) async {
    final response = await ref.watch(_dashboardResponseProvider.future);
    return response.toDomain();
  },
);

/// Driver hiring & inspection snapshot - REUSES dashboard response.
/// Does NOT make a second API call.
final hiringSnapshotProvider = FutureProvider<HiringSnapshot>(
  (ref) async {
    final response = await ref.watch(_dashboardResponseProvider.future);
    return response.driverInspector.toHiringSnapshot();
  },
);

/// Recent activity feed (5 items).
final activityFeedProvider = FutureProvider<List<ActivityItem>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchActivityFeed(),
);

/// Unread notification count.
final notificationCountProvider = FutureProvider<int>((ref) async {
  try {
    return await ref.watch(dashboardApiProvider).getNotificationCount();
  } catch (e) {
    return 0;
  }
});
