import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/connectivity.dart';

/// Refetches a screen's data whenever the user navigates back to it.
///
/// Marking providers `autoDispose` is not enough on its own: every bottom-nav
/// branch stays alive inside `StatefulShellRoute.indexedStack`, and a list
/// screen stays mounted underneath a pushed detail route — so nothing is ever
/// disposed and the cached data is reused. This widget closes that gap by
/// watching the router and refetching when its [path] becomes current again
/// (tab re-selected, or a pushed route popped).
///
/// Applied once per route in `app_router.dart`, so screens themselves stay
/// untouched:
///
/// ```dart
/// GoRoute(
///   path: Routes.bookings,
///   builder: (context, state) => const RevisitRefresher(
///     path: Routes.bookings,
///     onRevisit: refreshBookings,
///     child: BookingsScreen(),
///   ),
/// )
/// ```
class RevisitRefresher extends ConsumerStatefulWidget {
  const RevisitRefresher({
    required this.path,
    required this.onRevisit,
    required this.child,
    super.key,
  });

  /// The route pattern this screen is registered under — matched against
  /// `GoRouterState.fullPath`.
  final String path;

  /// Refetches the screen's data. Use the same helper the screen's
  /// pull-to-refresh calls so the two cannot drift apart.
  final Future<void> Function(WidgetRef ref) onRevisit;

  final Widget child;

  @override
  ConsumerState<RevisitRefresher> createState() => _RevisitRefresherState();
}

class _RevisitRefresherState extends ConsumerState<RevisitRefresher> {
  GoRouter? _router;
  bool _wasCurrent = true;
  bool _refreshing = false;

  bool get _isCurrentRoute => _router?.state.fullPath == widget.path;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_handleRouteChange);
    _router = router;
    // The screen is being built because its route just became current — that
    // first load is the builder's job, so only later returns should refetch.
    _wasCurrent = true;
    router.routerDelegate.addListener(_handleRouteChange);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (!mounted) return;
    final isCurrent = _isCurrentRoute;
    // Fire only on the transition back *into* this route, never on the
    // repeated notifications while it stays current.
    if (isCurrent && !_wasCurrent) {
      _refresh('Revisited');
    }
    _wasCurrent = isCurrent;
  }

  /// [reason] only labels the log line; the guard makes concurrent triggers
  /// (a route change landing at the same moment as a reconnect) collapse to one.
  Future<void> _refresh(String reason) async {
    if (_refreshing) return;
    _refreshing = true;
    debugPrint('🔄 $reason ${widget.path} — refetching');
    try {
      await widget.onRevisit(ref);
    } catch (_) {
      // The screen's own error state surfaces this; a failed background
      // refresh must not crash navigation.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-retry once when the connection comes back, per
    // `docs/HIVE implementation.md` — listen to the stream, don't poll.
    //
    // Guarded on `_isCurrentRoute` because bottom-nav branches all stay alive
    // inside the indexed stack: without it, reconnecting would refetch every
    // tab at once instead of the one being looked at.
    ref.listen<bool>(isOnlineProvider, (wasOnline, isOnline) {
      if (isOnline && wasOnline == false && _isCurrentRoute) {
        _refresh('Back online on');
      }
    });
    return widget.child;
  }
}
