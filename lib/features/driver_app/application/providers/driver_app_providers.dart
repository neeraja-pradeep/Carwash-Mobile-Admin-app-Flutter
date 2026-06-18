import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/drivers/application/providers/drivers_providers.dart';
import '../../../../features/drivers/domain/entities/driver_earnings.dart';
import '../../../../features/drivers/domain/entities/driver_job.dart';
import '../../../../features/drivers/domain/entities/field_driver.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/driver_app_repository.dart';
import '../../infrastructure/data_sources/local/driver_app_local_ds.dart';
import '../../infrastructure/data_sources/earnings_api.dart';
import '../../infrastructure/data_sources/worker_profile_api.dart';
import '../../infrastructure/data_sources/logout_api.dart';
import '../../infrastructure/repositories/driver_app_repository_impl.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (swapped for a remote+cache source in the API phase).
final driverAppLocalDsProvider = Provider<DriverAppLocalDs>(
  (ref) => const DriverAppLocalDs(),
);

/// Earnings API data source.
final earningsApiProvider = Provider<EarningsApi>(
  (ref) => EarningsApi(),
);

/// Worker Profile API data source.
final workerProfileApiProvider = Provider<WorkerProfileApi>(
  (ref) => WorkerProfileApi(),
);

/// Logout API data source.
final logoutApiProvider = Provider<LogoutApi>(
  (ref) => LogoutApi(),
);

/// The driver-app repository (domain contract → infrastructure impl).
final driverAppRepositoryProvider = Provider<DriverAppRepository>(
  (ref) => DriverAppRepositoryImpl(
    ref.watch(driverAppLocalDsProvider),
    earningsApi: ref.watch(earningsApiProvider),
    workerProfileApi: ref.watch(workerProfileApiProvider),
  ),
);

// ── Entity providers ─────────────────────────────────────────────────────────

/// All driver jobs (active + upcoming + completed). Kept alive so navigation
/// back is instant (warm cache).
final driverJobsProvider = FutureProvider<List<DriverJob>>(
  (ref) => ref.watch(driverAppRepositoryProvider).fetchDriverJobs(),
);

/// A single driver job by id (autoDispose — resets when detail screen is gone).
final driverJobByIdProvider =
    FutureProvider.autoDispose.family<DriverJob?, String>((ref, id) async {
  final jobs = await ref.watch(driverJobsProvider.future);
  try {
    return jobs.firstWhere((j) => j.id == id);
  } on StateError {
    return null;
  }
});

/// The signed-in driver's earnings summary. Kept alive with jobs.
final driverEarningsProvider = FutureProvider<DriverEarnings>(
  (ref) => ref.watch(driverAppRepositoryProvider).fetchDriverEarnings(),
);

/// The signed-in worker's profile. Fetched from the driver app API.
final workerProfileProvider = FutureProvider<WorkerProfile>(
  (ref) => ref.watch(driverAppRepositoryProvider).fetchWorkerProfile(),
);

/// The signed-in driver profile (fd1 — Manoj Kumar in the demo).
/// Reads from the shared drivers feature's [fieldDriverByIdProvider].
final signedInDriverProvider = FutureProvider<FieldDriver?>(
  (ref) => ref.watch(fieldDriverByIdProvider('fd1').future),
);

// ── UI state providers ───────────────────────────────────────────────────────

/// Online / offline toggle. `true` = online (accepting jobs). Shared across the
/// driver tabs (the persistent header in [DriverShell] owns the toggle), so it
/// is NOT autoDispose — the chosen state stays consistent as the driver moves
/// between Today / Schedule / Earnings / Profile. The Start/End job OTP flow is
/// held in local widget state on the job-detail screen (it transitions the
/// visible status), so no provider is needed for it.
final driverOnlineProvider = StateProvider<bool>(
  (ref) => true,
);

/// Logout function - clears session and returns to login screen.
/// Usage: await ref.read(logoutProvider)(context);
final logoutProvider = Provider<Future<void> Function()>((ref) {
  final logoutApi = ref.watch(logoutApiProvider);
  return () => logoutApi.logout();
});
