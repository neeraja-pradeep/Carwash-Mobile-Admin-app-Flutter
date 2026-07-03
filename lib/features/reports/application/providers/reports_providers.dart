import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/report_data.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../infrastructure/data_sources/reports_api.dart';
import '../../infrastructure/repositories/reports_repository_impl.dart';

/// API data source.
final reportsApiProvider = Provider<ReportsApi>((ref) => ReportsApi());

/// The reports repository (domain contract → API-backed impl).
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(api: ref.watch(reportsApiProvider)),
);

/// Selected report kind key — autoDispose.
final selectedReportProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

// ─── Per-report data providers (keyed by the period query) ────────────────────

final revenueReportProvider =
    FutureProvider.autoDispose.family<RevenueReport, ReportQuery>(
  (ref, query) => ref.watch(reportsRepositoryProvider).fetchRevenue(query),
);

final driversReportProvider =
    FutureProvider.autoDispose.family<DriversReport, ReportQuery>(
  (ref, query) =>
      ref.watch(reportsRepositoryProvider).fetchDriversInspectors(query),
);

final shopPerformanceReportProvider =
    FutureProvider.autoDispose.family<ShopPerformanceReport, ReportQuery>(
  (ref, query) =>
      ref.watch(reportsRepositoryProvider).fetchShopPerformance(query),
);

final commissionReportProvider =
    FutureProvider.autoDispose.family<CommissionReport, ReportQuery>(
  (ref, query) => ref.watch(reportsRepositoryProvider).fetchCommission(query),
);

final cancellationsReportProvider =
    FutureProvider.autoDispose.family<CancellationsReport, ReportQuery>(
  (ref, query) =>
      ref.watch(reportsRepositoryProvider).fetchCancellations(query),
);

final inspectionsReportProvider =
    FutureProvider.autoDispose.family<InspectionsReport, ReportQuery>(
  (ref, query) => ref.watch(reportsRepositoryProvider).fetchInspections(query),
);
