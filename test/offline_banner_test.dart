import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/dimens.dart';
import 'package:new_flutter_project/core/network/connectivity.dart';
import 'package:new_flutter_project/core/utils/screen_refresh.dart';
import 'package:new_flutter_project/core/widgets/offline_banner.dart';

/// `connectivity_plus` was a declared dependency the app never used, so losing
/// signal showed nothing at all — QA.md defects #11 and #12.
///
/// The behaviour spec'd in `docs/HIVE implementation.md`: a persistent
/// indicator, no polling, and a single refetch when the connection returns —
/// all without hiding data the screen already loaded.
void main() {
  late StreamController<bool> status;

  setUp(() => status = StreamController<bool>.broadcast());
  tearDown(() => status.close());

  List<Override> overrides() => [
        connectivityProvider.overrideWith((ref) => status.stream),
      ];

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: ScreenUtilInit(
          designSize: const Size(Dimens.designWidth, Dimens.designHeight),
          builder: (_, __) => MaterialApp(home: OfflineBanner(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const content = Scaffold(body: Center(child: Text('Bookings list')));

  group('the strip', () {
    testWidgets('stays hidden while the first status resolves', (tester) async {
      await pump(tester, content);

      // Nothing has been emitted yet — assume online rather than flashing an
      // offline strip during startup.
      expect(find.textContaining('No internet'), findsNothing);
      expect(find.text('Bookings list'), findsOneWidget);
    });

    testWidgets('appears when the connection drops', (tester) async {
      await pump(tester, content);

      status.add(false);
      await tester.pumpAndSettle();

      expect(find.textContaining('No internet'), findsOneWidget);
    });

    testWidgets('never hides what the screen already loaded', (tester) async {
      await pump(tester, content);

      status.add(false);
      await tester.pumpAndSettle();

      // The whole point: an indicator, not a takeover. The page stays readable.
      expect(find.text('Bookings list'), findsOneWidget);
    });

    testWidgets('goes away when the connection returns', (tester) async {
      await pump(tester, content);

      status.add(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('No internet'), findsOneWidget);

      status.add(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('No internet'), findsNothing);
    });
  });

  group('auto-retry on reconnect', () {
    /// A one-route app wrapped in the same refresher `app_router.dart` applies.
    Future<int Function()> pumpRoute(WidgetTester tester) async {
      var refreshes = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/list',
            builder: (_, __) => RevisitRefresher(
              path: '/list',
              onRevisit: (ref) async => refreshes++,
              child: content,
            ),
          ),
        ],
        initialLocation: '/list',
      );
      addTearDown(router.dispose);

      tester.view.physicalSize = const Size(1560, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: ScreenUtilInit(
            designSize: const Size(Dimens.designWidth, Dimens.designHeight),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return () => refreshes;
    }

    testWidgets('refetches once when the connection comes back',
        (tester) async {
      final refreshes = await pumpRoute(tester);

      status.add(false);
      await tester.pumpAndSettle();
      expect(refreshes(), 0, reason: 'going offline must not refetch');

      status.add(true);
      await tester.pumpAndSettle();
      expect(refreshes(), 1);
    });

    testWidgets('does not refetch on repeated online events', (tester) async {
      final refreshes = await pumpRoute(tester);

      status.add(true);
      await tester.pumpAndSettle();
      status.add(true);
      await tester.pumpAndSettle();

      // Only the offline→online edge counts — no polling, no repeats.
      expect(refreshes(), 0);
    });

    testWidgets('refetches again after a second drop', (tester) async {
      final refreshes = await pumpRoute(tester);

      status.add(false);
      await tester.pumpAndSettle();
      status.add(true);
      await tester.pumpAndSettle();
      expect(refreshes(), 1);

      status.add(false);
      await tester.pumpAndSettle();
      status.add(true);
      await tester.pumpAndSettle();
      expect(refreshes(), 2);
    });
  });
}
