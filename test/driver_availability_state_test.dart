import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/driver_app/application/providers/driver_home_provider.dart';
import 'package:new_flutter_project/features/driver_app/application/states/driver_home_state.dart';
import 'package:new_flutter_project/features/driver_app/domain/entities/availability.dart';
import 'package:new_flutter_project/features/driver_app/domain/entities/job_feed.dart';
import 'package:new_flutter_project/features/driver_app/domain/entities/stats.dart';
import 'package:new_flutter_project/features/driver_app/domain/repositories/driver_home_repository.dart';

Availability online(bool value) => Availability(
      status: value ? 'active' : 'inactive',
      online: value,
      onJob: false,
      role: 'driver',
    );

Stats get _stats => Stats(
      period: 'today',
      start: '2026-08-20',
      end: '2026-08-20',
      earnings: '0',
      jobs: 0,
      pending: '0',
    );

JobFeed get _feed => JobFeed(activeNow: const [], upNext: const [], count: 0);

/// Availability always resolves; [statsFails] / [feedFails] simulate the
/// secondary calls dying the way a flaky connection makes them.
class FakeRepo implements DriverHomeRepository {
  FakeRepo({this.statsFails = false, this.feedFails = false, this.isOnline = true});

  final bool statsFails;
  final bool feedFails;
  bool isOnline;

  @override
  Future<Availability> getAvailability() async => online(isOnline);

  @override
  Future<Availability> setAvailability({required bool online}) async {
    isOnline = online;
    return online ? _onlineTrue : _onlineFalse;
  }

  static final _onlineTrue = online(true);
  static final _onlineFalse = online(false);

  @override
  Future<Stats> getStats({String? period = 'today', String? start, String? end}) async {
    if (statsFails) throw Exception('stats endpoint down');
    return _stats;
  }

  @override
  Future<JobFeed> getJobFeed({String? date}) async {
    if (feedFails) throw Exception('feed endpoint down');
    return _feed;
  }
}

void main() {
  group('availability survives a partial home load', () {
    // The reported bug: the driver app showed "Offline" while the server (and
    // therefore the admin console) reported the driver online. The header read
    // availability only from DriverHomeSuccess, so any failure in the *other*
    // two calls silently rendered as offline.

    test('a stats failure does not discard a fetched online flag', () async {
      final notifier = DriverHomeNotifier(FakeRepo(statsFails: true));
      await notifier.loadHomeData();

      expect(notifier.state, isA<DriverHomeError>());
      expect(notifier.state.availability, isNotNull);
      expect(notifier.state.availability!.online, isTrue);
    });

    test('a feed failure does not discard a fetched online flag', () async {
      final notifier = DriverHomeNotifier(FakeRepo(feedFails: true));
      await notifier.loadHomeData();

      expect(notifier.state, isA<DriverHomeError>());
      expect(notifier.state.availability!.online, isTrue);
    });

    test('a successful load reports the server flag', () async {
      final notifier = DriverHomeNotifier(FakeRepo(isOnline: false));
      await notifier.loadHomeData();

      expect(notifier.state, isA<DriverHomeSuccess>());
      expect(notifier.state.availability!.online, isFalse);
    });

    test('never fetched is null — unknown, which is not the same as offline',
        () {
      final notifier = DriverHomeNotifier(FakeRepo());
      expect(notifier.state, isA<DriverHomeInitial>());
      expect(notifier.state.availability, isNull);
    });
  });
}
