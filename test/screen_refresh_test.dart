import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:new_flutter_project/core/utils/screen_refresh.dart';

/// [RevisitRefresher] is what makes navigating back to a screen refetch its
/// data. Both cases it must cover are exercised here: switching bottom-nav
/// branches (which keeps every screen alive inside an IndexedStack) and popping
/// a pushed detail route.
void main() {
  late List<String> refreshed;

  Widget harness(GoRouter router) => ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      );

  Widget tab(String path, String label) => RevisitRefresher(
        path: path,
        onRevisit: (ref) async => refreshed.add(path),
        child: Scaffold(body: Text(label)),
      );

  setUp(() => refreshed = []);

  testWidgets('refetches when a bottom-nav branch is re-selected',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    late StatefulNavigationShell shell;

    final router = GoRouter(
      navigatorKey: navKey,
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            shell = navigationShell;
            return navigationShell;
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/a', builder: (_, __) => tab('/a', 'A')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/b', builder: (_, __) => tab('/b', 'B')),
            ]),
          ],
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();
    expect(refreshed, isEmpty, reason: 'first build must not refetch');

    shell.goBranch(1); // → /b, built for the first time
    await tester.pumpAndSettle();
    expect(refreshed, isEmpty,
        reason: 'a first-built branch loads its own data');

    shell.goBranch(0); // back to /a, which stayed alive in the IndexedStack
    await tester.pumpAndSettle();
    expect(refreshed, ['/a']);

    shell.goBranch(1); // back to /b, now alive too
    await tester.pumpAndSettle();
    expect(refreshed, ['/a', '/b']);
  });

  testWidgets('refetches when a pushed route is popped', (tester) async {
    final navKey = GlobalKey<NavigatorState>();

    final router = GoRouter(
      navigatorKey: navKey,
      initialLocation: '/list',
      routes: [
        GoRoute(path: '/list', builder: (_, __) => tab('/list', 'List')),
        GoRoute(
          path: '/detail',
          builder: (_, __) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();
    expect(refreshed, isEmpty);

    router.push('/detail');
    await tester.pumpAndSettle();
    expect(refreshed, isEmpty, reason: 'pushing away must not refetch');

    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(refreshed, ['/list']);
  });
}
