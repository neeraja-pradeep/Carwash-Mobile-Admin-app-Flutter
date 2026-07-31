import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/auth/auth_session_signal.dart';
import '../core/widgets/offline_banner.dart';
import '../features/auth/application/providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme/dimens.dart';
import 'theme/theme.dart';

/// Root widget. Initialises `flutter_screenutil` against the 380×800 design
/// baseline, pins the text scale to 1.0, and mounts the GoRouter config.
class DriveDeckApp extends StatelessWidget {
  const DriveDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(Dimens.designWidth, Dimens.designHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      // On some startup paths (notably the Android emulator with Impeller) the
      // render surface briefly reports a 0×0 size. ScreenUtil would then scale
      // every `.sp`/`.w`/`.h`/`.r` value to 0, tripping Flutter asserts
      // (`fontSize > 0`, infinite-height, unsized RenderBox …) so the UI fails
      // to lay out. `ensureScreenSize` defers the first frame until the view
      // reports a real size, so scaling is always computed against valid metrics.
      ensureScreenSize: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Drivey Admin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
          builder: (context, routerChild) {
            // Pin text scaling so the design renders 1:1 with ScreenUtil sizing.
            return MediaQuery.withNoTextScaling(
              // Mounted here rather than per screen so every route — including
              // pushed details and bottom-nav branches — shows the same strip.
              child: _SessionExpiryBridge(
                child: OfflineBanner(
                  child: routerChild ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Bridges the router-level [AuthSessionSignal] back into Riverpod.
///
/// The 401 interceptor can only flip the signal — it has no provider container.
/// This listener does the rest: clearing the cached user and session so the
/// next launch starts at login instead of restoring a session the server has
/// already thrown away. The router handles the navigation itself via
/// `refreshListenable`.
class _SessionExpiryBridge extends ConsumerStatefulWidget {
  const _SessionExpiryBridge({required this.child});

  final Widget child;

  @override
  ConsumerState<_SessionExpiryBridge> createState() =>
      _SessionExpiryBridgeState();
}

class _SessionExpiryBridgeState extends ConsumerState<_SessionExpiryBridge> {
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    AuthSessionSignal.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    AuthSessionSignal.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final signal = AuthSessionSignal.instance;
    if (_clearing || signal.isAuthenticated || !signal.wasExpired) return;

    _clearing = true;
    ref
        .read(authStateProvider.notifier)
        .handleSessionExpired()
        .whenComplete(() => _clearing = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
