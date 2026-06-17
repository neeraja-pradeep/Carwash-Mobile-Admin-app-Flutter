import '../../domain/entities/availability.dart';
import '../../domain/entities/stats.dart';
import '../../domain/entities/job_feed.dart';
import '../../domain/repositories/driver_home_repository.dart';
import '../data_sources/driver_home_api.dart';

class DriverHomeRepositoryImpl implements DriverHomeRepository {
  final DriverHomeApi _api = DriverHomeApi();

  @override
  Future<Availability> getAvailability() async {
    final model = await _api.getAvailability();
    return model.toEntity();
  }

  @override
  Future<Availability> setAvailability({required bool online}) async {
    final model = await _api.setAvailability(online: online);
    return model.toEntity();
  }

  @override
  Future<Stats> getStats({
    String? period = 'today',
    String? start,
    String? end,
  }) async {
    final model = await _api.getStats(
      period: period,
      start: start,
      end: end,
    );
    return model.toEntity();
  }

  @override
  Future<JobFeed> getJobFeed({String? date}) async {
    final model = await _api.getJobFeed(date: date);
    return model.toEntity();
  }
}
