import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../infrastructure/data_sources/local/reports_local_ds.dart';
import '../../infrastructure/repositories/reports_repository_impl.dart';

final _reportsLocalDsProvider = Provider<ReportsLocalDs>(
  (ref) => const ReportsLocalDs(),
);

/// The reports repository (domain contract → infrastructure impl).
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(_reportsLocalDsProvider)),
);

/// Daily summary data.
final dailySummaryProvider = FutureProvider<DailySummary>(
  (ref) => ref.watch(reportsRepositoryProvider).fetchDailySummary(),
);

/// Selected report kind key — autoDispose.
final selectedReportProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Selected period key — autoDispose.
final selectedPeriodProvider = StateProvider.autoDispose<String>(
  (ref) => 'today',
);
