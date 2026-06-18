import 'package:flutter/foundation.dart';

import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/driver_app_repository.dart';
import '../data_sources/local/driver_app_local_ds.dart';
import '../data_sources/earnings_api.dart';
import '../data_sources/worker_profile_api.dart';

/// Fulfils [DriverAppRepository] from local and remote data sources.
class DriverAppRepositoryImpl implements DriverAppRepository {
  const DriverAppRepositoryImpl(
    this._local, {
    EarningsApi? earningsApi,
    WorkerProfileApi? workerProfileApi,
  })  : _earningsApi = earningsApi,
        _workerProfileApi = workerProfileApi;

  final DriverAppLocalDs _local;
  final EarningsApi? _earningsApi;
  final WorkerProfileApi? _workerProfileApi;

  @override
  Future<List<DriverJob>> fetchDriverJobs() => _local.fetchDriverJobs();

  @override
  Future<DriverEarnings> fetchDriverEarnings() async {
    final api = _earningsApi;
    if (api != null) {
      try {
        final summary = await api.getEarningsSummary();
        return summary.toEntity();
      } catch (e) {
        // Fall back to local data if API fails
        debugPrint('Failed to fetch earnings from API: $e');
      }
    }
    return _local.fetchDriverEarnings();
  }

  @override
  Future<WorkerProfile> fetchWorkerProfile() async {
    final api = _workerProfileApi;
    if (api != null) {
      try {
        final model = await api.getWorkerProfile();
        return model.toEntity();
      } catch (e) {
        // Fall back to local data if API fails
        debugPrint('Failed to fetch worker profile from API: $e');
      }
    }
    return _local.fetchWorkerProfile();
  }
}
