import 'package:flutter/foundation.dart';

import '../../../drivers/domain/entities/driver_earnings.dart';
import '../../../drivers/domain/entities/driver_job.dart';
import '../../domain/repositories/driver_app_repository.dart';
import '../data_sources/local/driver_app_local_ds.dart';
import '../data_sources/earnings_api.dart';

/// Fulfils [DriverAppRepository] from local and remote data sources.
class DriverAppRepositoryImpl implements DriverAppRepository {
  const DriverAppRepositoryImpl(
    this._local, {
    EarningsApi? earningsApi,
  }) : _earningsApi = earningsApi;

  final DriverAppLocalDs _local;
  final EarningsApi? _earningsApi;

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
}
