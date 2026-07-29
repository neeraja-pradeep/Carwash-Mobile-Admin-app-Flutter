import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a usable network interface.
///
/// **What this detects.** `connectivity_plus` reports the *interface* — Wi-Fi,
/// mobile, ethernet, VPN — not whether packets actually reach the API. A device
/// attached to a captive-portal Wi-Fi reads as online here and its requests
/// still fail. That is the right trade-off for an indicator: it never lies about
/// being offline, and genuine request failures are surfaced by each screen's own
/// `ErrorView`. Anything stronger would mean polling a health endpoint, which
/// costs battery and requests for a rare case.
///
/// Per `docs/HIVE implementation.md`: listen to the stream rather than retrying
/// on a timer, and refetch **once** when the connection returns.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty &&
      results.any((r) => r != ConnectivityResult.none);

  /// Emits the current status immediately, then on every change.
  ///
  /// Failures to read the platform channel resolve to `true`: an indicator that
  /// wrongly claims the app is offline is worse than one that stays quiet, since
  /// real request failures are reported by the screens themselves.
  Stream<bool> watch() async* {
    try {
      yield _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      yield true;
    }
    yield* _connectivity.onConnectivityChanged
        .map(_isOnline)
        .handleError((Object _) {});
  }

  Future<bool> isOnline() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      return true;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// `true` when the device has a network interface. Not autoDispose — this is
/// app-wide state and the subscription should outlive any one screen.
final connectivityProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).watch(),
);

/// The banner and the refetch-on-reconnect hook both read this.
///
/// Defaults to online while the first status is still resolving, so the banner
/// never flashes during startup.
final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityProvider).value ?? true,
);
