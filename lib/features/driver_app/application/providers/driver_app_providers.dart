import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/drivers/application/providers/drivers_providers.dart';
import '../../../../features/drivers/domain/entities/driver_earnings.dart';
import '../../../../features/drivers/domain/entities/driver_job.dart';
import '../../../../features/drivers/domain/entities/field_driver.dart';
import '../../domain/repositories/driver_app_repository.dart';
import '../../infrastructure/data_sources/local/driver_app_local_ds.dart';
import '../../infrastructure/repositories/driver_app_repository_impl.dart';

// ── Data layer providers ─────────────────────────────────────────────────────

/// Local data source (swapped for a remote+cache source in the API phase).
final driverAppLocalDsProvider = Provider<DriverAppLocalDs>(
  (ref) => const DriverAppLocalDs(),
);

/// The driver-app repository (domain contract → infrastructure impl).
final driverAppRepositoryProvider = Provider<DriverAppRepository>(
  (ref) => DriverAppRepositoryImpl(ref.watch(driverAppLocalDsProvider)),
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

/// The signed-in driver profile (fd1 — Manoj Kumar in the demo).
/// Reads from the shared drivers feature's [fieldDriverByIdProvider].
final signedInDriverProvider = FutureProvider<FieldDriver?>(
  (ref) => ref.watch(fieldDriverByIdProvider('fd1').future),
);

// ── UI state providers (autoDispose — reset on navigation) ───────────────────

/// Online / offline toggle. `true` = online (accepting jobs). The Start/End
/// job OTP flow is held in local widget state on the job-detail screen (it
/// transitions the visible status), so no provider is needed for it.
final driverOnlineProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);
