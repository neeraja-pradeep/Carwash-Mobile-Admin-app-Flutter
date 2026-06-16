import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/bookings/presentation/screens/bookings_screen.dart';
import '../../features/bookings/presentation/screens/new_booking_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
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
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The application's GoRouter configuration.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.login,
  routes: [
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
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.bookings,
              builder: (context, state) => const BookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.drivers,
              builder: (context, state) => const DriversScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.customers,
              builder: (context, state) => const CustomersScreen(),
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
      builder: (context, state) => const ShopsScreen(),
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
      builder: (context, state) => const ReviewsScreen(),
    ),
    GoRoute(
      path: Routes.refunds,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RefundsScreen(),
    ),
    GoRoute(
      path: Routes.payouts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PayoutsScreen(),
    ),
    GoRoute(
      path: Routes.offers,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OffersScreen(),
    ),
    GoRoute(
      path: Routes.reports,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.serviceAreas,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ServiceAreasScreen(),
    ),
    GoRoute(
      path: Routes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
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
              builder: (context, state) => const DriverTodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverSchedule,
              builder: (context, state) => const DriverScheduleScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverEarnings,
              builder: (context, state) => const DriverEarningsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.driverProfile,
              builder: (context, state) => const DriverProfileScreen(),
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
  ],
);
