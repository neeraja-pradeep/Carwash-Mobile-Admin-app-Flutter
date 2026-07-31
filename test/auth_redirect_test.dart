import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/core/auth/auth_session_signal.dart';

/// A stand-in for `appRouter` wired to the same guard and the same signal, but
/// with placeholder screens so the test doesn't need the network or Hive.
GoRouter buildGuardedRouter() {
  Widget page(String label) => Scaffold(body: Text(label));

  return GoRouter(
    initialLocation: Routes.authCheck,
    refreshListenable: AuthSessionSignal.instance,
    redirect: (context, state) => authGuard(
      isAuthenticated: AuthSessionSignal.instance.isAuthenticated,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.authCheck, builder: (_, __) => page('auth-check')),
      GoRoute(path: Routes.login, builder: (_, __) => page('login')),
      GoRoute(path: Routes.dashboard, builder: (_, __) => page('dashboard')),
      GoRoute(path: Routes.bookings, builder: (_, __) => page('bookings')),
      GoRoute(path: Routes.driverToday, builder: (_, __) => page('today')),
    ],
  );
}

void main() {
  setUp(() => AuthSessionSignal.instance.markSignedOut());
  tearDown(() => AuthSessionSignal.instance.markSignedOut());

  group('authGuard', () {
    test('sends an operator without a session to login', () {
      expect(
        authGuard(isAuthenticated: false, location: Routes.dashboard),
        Routes.login,
      );
      expect(
        authGuard(isAuthenticated: false, location: Routes.driverToday),
        Routes.login,
      );
    });

    test('leaves the login and startup screens reachable', () {
      expect(authGuard(isAuthenticated: false, location: Routes.login), isNull);
      expect(
        authGuard(isAuthenticated: false, location: Routes.authCheck),
        isNull,
      );
    });

    test('stays put once a session exists', () {
      expect(
        authGuard(isAuthenticated: true, location: Routes.dashboard),
        isNull,
      );
    });
  });

  group('AuthSessionSignal', () {
    test('a rejected session both closes the gate and flags the expiry', () {
      final signal = AuthSessionSignal.instance;
      signal.markAuthenticated();
      expect(signal.isAuthenticated, isTrue);

      signal.markSessionExpired();
      expect(signal.isAuthenticated, isFalse);
      expect(signal.wasExpired, isTrue);
    });

    test('the expiry notice is consumed once', () {
      final signal = AuthSessionSignal.instance;
      signal.markSessionExpired();

      expect(signal.consumeExpiredFlag(), isTrue);
      expect(signal.consumeExpiredFlag(), isFalse);
    });

    test('an operator-initiated sign-out is not reported as an expiry', () {
      final signal = AuthSessionSignal.instance;
      signal.markAuthenticated();
      signal.markSignedOut();

      expect(signal.isAuthenticated, isFalse);
      expect(signal.wasExpired, isFalse);
    });

    test('repeat rejections while already signed out do not re-notify', () {
      final signal = AuthSessionSignal.instance;
      var notifications = 0;
      void count() => notifications++;
      signal.addListener(count);
      addTearDown(() => signal.removeListener(count));

      signal.markAuthenticated();
      // A screen firing five parallel calls that all 401 must settle to one
      // sign-out, not five router refreshes.
      for (var i = 0; i < 5; i++) {
        signal.markSessionExpired();
      }

      expect(notifications, 2); // authenticated, then expired
    });
  });

  group('router', () {
    testWidgets('a protected route is unreachable without a session',
        (tester) async {
      final router = buildGuardedRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.go(Routes.dashboard);
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.text('dashboard'), findsNothing);
    });

    testWidgets('a session rejected mid-use bounces back to login',
        (tester) async {
      AuthSessionSignal.instance.markAuthenticated();
      final router = buildGuardedRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go(Routes.bookings);
      await tester.pumpAndSettle();
      expect(find.text('bookings'), findsOneWidget);

      // What the 401 interceptor does when the server drops the session.
      AuthSessionSignal.instance.markSessionExpired();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.text('bookings'), findsNothing);
    });

    testWidgets('signing in reopens the protected routes', (tester) async {
      final router = buildGuardedRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(Routes.dashboard);
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);

      AuthSessionSignal.instance.markAuthenticated();
      router.go(Routes.dashboard);
      await tester.pumpAndSettle();

      expect(find.text('dashboard'), findsOneWidget);
    });
  });
}
