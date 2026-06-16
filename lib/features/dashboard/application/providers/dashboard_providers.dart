import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../infrastructure/data_sources/local/dashboard_local_ds.dart';
import '../../infrastructure/repositories/dashboard_repository_impl.dart';

/// Local data source provider (swapped for a remote+cache source in the API phase).
final dashboardLocalDsProvider = Provider<DashboardLocalDs>(
  (ref) => const DashboardLocalDs(),
);

/// The dashboard repository (domain contract → infrastructure impl).
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardLocalDsProvider)),
);

/// Carwash operational snapshot for today.
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchDashboardSnapshot(),
);

/// Driver hiring & inspection snapshot.
final hiringSnapshotProvider = FutureProvider<HiringSnapshot>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchHiringSnapshot(),
);

/// Recent activity feed (5 items).
final activityFeedProvider = FutureProvider<List<ActivityItem>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchActivityFeed(),
);
