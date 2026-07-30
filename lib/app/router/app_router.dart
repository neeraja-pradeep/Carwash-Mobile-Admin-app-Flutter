import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/utils/screen_refresh.dart';
import '../../features/auth/presentation/screens/auth_check_screen.dart';
import '../../features/bookings/application/providers/bookings_providers.dart';
import '../../features/customers/application/providers/customers_providers.dart';
import '../../features/dashboard/application/providers/dashboard_providers.dart';
import '../../features/driver_app/application/providers/driver_app_providers.dart';
import '../../features/drivers/application/providers/drivers_providers.dart';
import '../../features/notifications/application/providers/notifications_providers.dart';
import '../../features/offers/application/providers/offers_providers.dart';
import '../../features/payouts/application/providers/payouts_providers.dart';
import '../../features/refunds/application/providers/refunds_providers.dart';
import '../../features/reviews/application/providers/reviews_providers.dart';
import '../../features/service_requests/application/providers/service_requests_providers.dart';
import '../../features/settings/application/providers/settings_providers.dart';
import '../../features/shops/application/providers/shops_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/bookings/presentation/screens/bookings_screen.dart';
import '../../features/bookings/presentation/screens/new_booking_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/driver_app/presentation/screens/driver_carwash_detail_screen.dart';
import '../../features/driver_app/presentation/screens/driver_earnings_screen.dart';
import '../../features/driver_app/presentation/screens/driver_job_detail_screen.dart';
import '../../features/driver_app/presentation/screens/driver_profile_screen.dart';
import '../../features/driver_app/presentation/screens/driver_schedule_screen.dart';
import '../../features/driver_app/presentation/screens/driver_today_screen.dart';
import '../../features/drivers/presentation/screens/driver_detail_screen.dart';
import '../../features/drivers/presentation/screens/drivers_screen.dart';
import '../../features/drivers/presentation/screens/hire_driver_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/push_notifications_screen.dart';
import '../../features/offers/presentation/screens/offers_screen.dart';
import '../../features/payouts/presentation/screens/payouts_screen.dart';
import '../../features/refunds/presentation/screens/new_refund_screen.dart'
    show RefundPrefill;
import '../../features/refunds/presentation/screens/refunds_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';
import '../../features/service_requests/domain/entities/service_request.dart';
import '../../features/service_requests/presentation/screens/new_service_request_screen.dart';
import '../../features/service_requests/presentation/screens/service_request_detail_screen.dart';
import '../../features/settings/presentation/screens/service_areas_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shops/presentation/screens/service_form_screen.dart';
import '../../features/shops/presentation/screens/shop_detail_screen.dart';
import '../../features/shops/presentation/screens/shop_form_screen.dart';
import '../../features/shops/presentation/screens/shop_hours_screen.dart';
import '../../features/shops/presentation/screens/shops_screen.dart';
import 'admin_shell.dart';
import 'driver_shell.dart';

/// Centralised route paths + typed builders. Use `context.push(Routes.x)` from
/// screens; bottom-nav tabs switch branches via the shell.
class Routes {
  const Routes._();

  static const String login = '/login';

  // Admin bottom-nav branches.
  static const String dashboard = '/admin/dashboard';
  static const String bookings = '/admin/bookings';
  static const String drivers = '/admin/drivers';
  static const String customers = '/admin/customers';

  // Admin pushed module / detail routes.
  static const String shops = '/admin/shops';
  static const String reviews = '/admin/reviews';
  static const String refunds = '/admin/refunds';
  static const String payouts = '/admin/payouts';
  static const String offers = '/admin/offers';
  static const String reports = '/admin/reports';
  static const String settings = '/admin/settings';
  static const String serviceAreas = '/admin/service-areas';
  static const String notifications = '/admin/notifications';
  static const String pushNotifications = '/admin/push-notifications';
  static const String newBooking = '/admin/new-booking';
  static const String hireDriver = '/admin/hire-driver';
  static const String addShop = '/admin/shop-add';

  static String bookingDetail(String id) => '/admin/booking/$id';
  static String serviceRequestDetail(String id) => '/admin/service-request/$id';
  static String newServiceRequest(SrKind kind) =>
      '/admin/new-request/${kind.name}';
  static String driverDetail(String id) => '/admin/driver/$id';
  static String shopDetail(String id) => '/admin/shop/$id';
  static String shopHours(String id) => '/admin/shop/$id/hours';
  static String editShop(String id) => '/admin/shop/$id/edit';
  static String addService(String shopId) => '/admin/shop/$shopId/service';
  static String editService(String shopId, String serviceId) =>
      '/admin/shop/$shopId/service?serviceId=$serviceId';
  static String customerDetail(String id) => '/admin/customer/$id';

  // Driver app.
  static const String driverToday = '/driver/today';
  static const String driverSchedule = '/driver/schedule';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';
  static String driverJob(String id) => '/driver/job/$id';
  static String driverCarwash(String id) => '/driver/carwash/$id';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The application's GoRouter configuration.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth-check',
  // Records a breadcrumb per route change so a crash report shows the screens
  // the operator passed through on the way there.
  observers: [SentryNavigatorObserver()],
  routes: [
    // Auth check screen — checks for existing session on startup
    GoRoute(
      path: '/auth-check',
      builder: (context, state) => const AuthCheckScreen(),
    ),

    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Admin bottom-nav shell ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.dashboard,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.dashboard,
                onRevisit: refreshDashboard,
                child: DashboardScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.bookings,
              // Hosts both the service-requests and carwash-bookings segments.
              builder: (context, state) => RevisitRefresher(
                path: Routes.bookings,
                onRevisit: (ref) async {
                  await refreshServiceRequests(ref);
                  await refreshBookings(ref);
                },
                child: const BookingsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.drivers,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.drivers,
                onRevisit: refreshDrivers,
                child: DriversScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.customers,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.customers,
                onRevisit: refreshCustomers,
                child: CustomersScreen(),
              ),
            ),
          ],
        ),
      ],
    ),

    // ── Admin pushed routes (cover the shell — no bottom nav) ──
    GoRoute(
      path: '/admin/booking/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          BookingDetailScreen(bookingId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/service-request/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ServiceRequestDetailScreen(requestId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.newBooking,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NewBookingScreen(),
    ),
    GoRoute(
      path: '/admin/new-request/:kind',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => NewServiceRequestScreen(
        kind: state.pathParameters['kind'] == SrKind.inspection.name
            ? SrKind.inspection
            : SrKind.driver,
      ),
    ),
    GoRoute(
      path: '/admin/driver/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          DriverDetailScreen(driverId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.hireDriver,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HireDriverScreen(),
    ),
    GoRoute(
      path: Routes.shops,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.shops,
        onRevisit: refreshShops,
        child: ShopsScreen(),
      ),
    ),
    GoRoute(
      path: Routes.addShop,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ShopFormScreen(),
    ),
    GoRoute(
      path: '/admin/shop/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ShopDetailScreen(shopId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/shop/:id/hours',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ShopHoursScreen(shopId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/shop/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ShopFormScreen(shopId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/admin/shop/:id/service',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ServiceFormScreen(
        shopId: state.pathParameters['id']!,
        serviceId: state.uri.queryParameters['serviceId'],
      ),
    ),
    GoRoute(
      path: '/admin/customer/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CustomerDetailScreen(customerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.reviews,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.reviews,
        onRevisit: refreshReviews,
        child: ReviewsScreen(),
      ),
    ),
    GoRoute(
      path: Routes.refunds,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RevisitRefresher(
        path: Routes.refunds,
        onRevisit: refreshRefunds,
        child: RefundsScreen(prefillBooking: state.extra as RefundPrefill?),
      ),
    ),
    GoRoute(
      path: Routes.payouts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RevisitRefresher(
        path: Routes.payouts,
        onRevisit: refreshPayouts,
        child: PayoutsScreen(prefillShopId: state.extra as String?),
      ),
    ),
    GoRoute(
      path: Routes.offers,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.offers,
        onRevisit: refreshOffers,
        child: OffersScreen(),
      ),
    ),
    GoRoute(
      path: Routes.reports,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.settings,
        onRevisit: refreshSettings,
        child: SettingsScreen(),
      ),
    ),
    GoRoute(
      path: Routes.serviceAreas,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.serviceAreas,
        onRevisit: refreshSettings,
        child: ServiceAreasScreen(),
      ),
    ),
    GoRoute(
      path: Routes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RevisitRefresher(
        path: Routes.notifications,
        onRevisit: refreshNotifications,
        child: NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: Routes.pushNotifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PushNotificationsScreen(),
    ),

    // ── Driver app bottom-nav shell ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          DriverShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverToday,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.driverToday,
                onRevisit: refreshDriverToday,
                child: DriverTodayScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverSchedule,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.driverSchedule,
                onRevisit: refreshDriverSchedule,
                child: DriverScheduleScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverEarnings,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.driverEarnings,
                onRevisit: refreshDriverEarnings,
                child: DriverEarningsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverProfile,
              builder: (context, state) => const RevisitRefresher(
                path: Routes.driverProfile,
                onRevisit: refreshDriverProfile,
                child: DriverProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/driver/job/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          DriverJobDetailScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/driver/carwash/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          DriverCarwashDetailScreen(bookingId: state.pathParameters['id']!),
    ),
  ],
);
