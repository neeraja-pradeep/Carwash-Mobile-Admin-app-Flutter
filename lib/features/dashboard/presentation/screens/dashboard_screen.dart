import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_icon_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/section_head.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';

import '../../application/providers/dashboard_providers.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/hiring_snapshot.dart';
import '../components/activity_row.dart';
import '../components/kpi_tile.dart';
import '../components/module_tile.dart';
import '../components/quick_action_tile.dart';

/// Landing screen of the admin shell (bottom-nav tab 0).
///
/// Sections (top to bottom):
///   1. Top bar — DriveDeck branding + notification bell
///   2. Driver Hiring & Inspection KPIs
///   3. Carwash · Today KPIs
///   4. Quick Actions 2×2 grid
///   5. More Tools 3-col grid
///   6. Recent Activity feed
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);
    final hiringAsync = ref.watch(hiringSnapshotProvider);
    final activityAsync = ref.watch(activityFeedProvider);
    final notificationAsync = ref.watch(notificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              firstName: snapshotAsync.valueOrNull?.adminName,
              notificationCount: notificationAsync.valueOrNull ?? 0,
              onNotifications: () => context.push(Routes.notifications),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => refreshDashboard(ref),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Driver Hiring & Inspection ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHead(
                              title: 'Driver Hiring & Inspection',
                              actionLabel: 'Manage',
                              onAction: () => context.go(Routes.drivers),
                            ),
                            hiringAsync.when(
                              loading: () => _KpiSkeletonGrid(),
                              error: (_, __) => _KpiSkeletonGrid(),
                              data: (h) => _HiringKpis(
                                hiring: h,
                                onDrivers: () => context.go(Routes.drivers),
                                onServices: () => context.go(Routes.bookings),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Carwash · Today ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHead(title: 'Carwash · Today'),
                            snapshotAsync.when(
                              loading: () => _KpiSkeletonGrid(),
                              error: (_, __) => _KpiSkeletonGrid(),
                              data: (s) => _CarwashKpis(
                                snapshot: s,
                                onBookings: () => context.go(Routes.bookings),
                                onRefunds: () => context.push(Routes.refunds),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Quick Actions ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHead(title: 'Quick Actions'),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 12.h,
                              childAspectRatio: 2.6,
                              children: [
                                QuickActionTile(
                                  icon: AppIcons.plus,
                                  label: 'New Booking',
                                  onTap: () => context.push(Routes.newBooking),
                                ),
                                QuickActionTile(
                                  icon: AppIcons.car,
                                  label: 'Assign Me',
                                  onTap: () => context.go(Routes.bookings),
                                ),
                                QuickActionTile(
                                  icon: AppIcons.receipt,
                                  label: 'New Refund',
                                  onTap: () => context.push(Routes.refunds),
                                ),
                                QuickActionTile(
                                  icon: AppIcons.search,
                                  label: 'Find Booking',
                                  onTap: () => context.go(Routes.bookings),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── More Tools ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHead(title: 'More Tools'),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 12.h,
                              // Order/labels mirror the More Tools grid in
                              // screen_dashboard.jsx (Drivers is a bottom-nav tab,
                              // not a tile here).
                              children: [
                                ModuleTile(
                                  icon: AppIcons.store,
                                  label: 'Shops',
                                  onTap: () => context.push(Routes.shops),
                                ),
                                ModuleTile(
                                  icon: AppIcons.message,
                                  label: 'Reviews',
                                  onTap: () => context.push(Routes.reviews),
                                ),
                                ModuleTile(
                                  icon: AppIcons.receipt,
                                  label: 'Refunds',
                                  // Pending-refund count badge (data-driven from
                                  // the snapshot; matches `badge={2}` in
                                  // screen_dashboard.jsx).
                                  badge:
                                      snapshotAsync.valueOrNull?.pendingRefunds,
                                  onTap: () => context.push(Routes.refunds),
                                ),
                                ModuleTile(
                                  icon: AppIcons.wallet,
                                  label: 'Payouts',
                                  onTap: () => context.push(Routes.payouts),
                                ),
                                ModuleTile(
                                  icon: AppIcons.tag,
                                  label: 'Offers',
                                  onTap: () => context.push(Routes.offers),
                                ),
                                ModuleTile(
                                  icon: AppIcons.chart,
                                  label: 'Reports',
                                  onTap: () => context.push(Routes.reports),
                                ),
                                ModuleTile(
                                  icon: AppIcons.bell,
                                  label: 'Push',
                                  onTap: () =>
                                      context.push(Routes.pushNotifications),
                                ),
                                ModuleTile(
                                  icon: AppIcons.gear,
                                  label: 'Settings',
                                  onTap: () => context.push(Routes.settings),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Recent Activity ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHead(
                              title: 'Recent Activity',
                              actionLabel: 'View all',
                              onAction: () => context.go(Routes.bookings),
                            ),
                            activityAsync.when(
                              loading: () => const SkeletonCard(),
                              error: (_, __) => const SkeletonCard(),
                              data: (feed) => _ActivityFeed(
                                feed: feed,
                                onItem: (id) =>
                                    context.push(Routes.bookingDetail(id)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onNotifications,
    this.firstName,
    this.notificationCount = 0,
  });

  final VoidCallback onNotifications;
  final String? firstName;
  final int notificationCount;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      >= 0 && < 12 => 'Good morning',
      >= 12 && < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    final name = firstName?.isNotEmpty == true ? firstName : 'there';
    return '$greeting, $name';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 12.h),
      child: Row(
        children: [
          // Brand logo badge
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.brandYellow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(AppIcons.car, size: 22.sp, color: AppColors.fgPrimary),
          ),
          SizedBox(width: 11.w),
          // App name + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DriveDeck',
                  style: AppText.figtree(
                    size: 18,
                    weight: FontWeight.w800,
                    color: AppColors.fgPrimary,
                    letterSpacing: -0.4,
                    height: 1,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _getGreeting(),
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell with badge
          AppIconButton(
            icon: AppIcons.bell,
            onTap: onNotifications,
            semanticLabel: 'Notifications',
            badge: notificationCount > 0 ? '$notificationCount' : null,
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hiring KPI 2×2 grid
// ─────────────────────────────────────────────

class _HiringKpis extends StatelessWidget {
  const _HiringKpis({
    required this.hiring,
    required this.onDrivers,
    required this.onServices,
  });

  final HiringSnapshot hiring;
  final VoidCallback onDrivers;
  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.35,
      children: [
        KpiTile(
          eyebrow: 'Drivers Online',
          value: '${hiring.driversOnline}/${hiring.driversTotal}',
          sub: '${hiring.onJobNow} on a job now',
          icon: AppIcons.car,
          onTap: onDrivers,
        ),
        KpiTile(
          eyebrow: 'Hire Requests',
          value: '${hiring.hireRequestsToday}',
          sub: hiring.hireOpen > 0
              ? '${hiring.hireOpen} needs assignee'
              : 'all assigned',
          icon: AppIcons.users,
          alert: hiring.hireOpen > 0,
          onTap: onServices,
        ),
        KpiTile(
          eyebrow: 'Inspections',
          value: '${hiring.inspectionsToday}',
          sub: hiring.inspectOpen > 0
              ? '${hiring.inspectOpen} open'
              : 'all assigned',
          icon: AppIcons.search,
          onTap: onServices,
        ),
        KpiTile(
          eyebrow: 'On a Job Now',
          value: '${hiring.onJobNow}',
          sub: 'live driver jobs',
          icon: AppIcons.nav,
          onTap: onDrivers,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Carwash snapshot KPI 2×2 grid
// ─────────────────────────────────────────────

class _CarwashKpis extends StatelessWidget {
  const _CarwashKpis({
    required this.snapshot,
    required this.onBookings,
    required this.onRefunds,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback onBookings;
  final VoidCallback onRefunds;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      // Slightly taller cells (was 1.2) so the two-line sub — e.g. Bookings
      // Today's "N waiting · N active · N done" — fits on larger font scales.
      childAspectRatio: 1.13,
      children: [
        // Overdue FIRST — alert when overdue > 0
        KpiTile(
          eyebrow: 'Overdue',
          value: '${snapshot.overdue}',
          sub: snapshot.overdue > 0 ? 'needs action now' : 'all on track',
          icon: AppIcons.alert,
          alert: snapshot.overdue > 0,
          onTap: onBookings,
        ),
        // Bookings Today
        KpiTile(
          eyebrow: 'Bookings Today',
          value: '${snapshot.bookingsToday}',
          sub: '${snapshot.waiting} waiting · '
              '${snapshot.inProgress} active · '
              '${snapshot.doneToday} done',
          icon: AppIcons.cal,
          onTap: onBookings,
        ),
        // Active Now
        KpiTile(
          eyebrow: 'Active Now',
          value: '${snapshot.activeNow}',
          sub: 'in progress right now',
          icon: AppIcons.droplet,
          onTap: onBookings,
        ),
        // Pending Refunds — amber sub-text colour
        KpiTile(
          eyebrow: 'Pending Refunds',
          value: '${snapshot.pendingRefunds}',
          sub: '${Formatters.money(snapshot.pendingRefundAmt)} pending',
          icon: AppIcons.receipt,
          subColor: AppColors.amberFg,
          onTap: onRefunds,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Recent activity feed card
// ─────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({
    required this.feed,
    required this.onItem,
  });

  final List<ActivityItem> feed;
  final void Function(String bookingId) onItem;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padded: false,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      child: Column(
        children: [
          for (int i = 0; i < feed.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
            ActivityRow(
              item: feed[i],
              onTap: () => onItem(feed[i].bookingId),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Skeleton placeholder for 2×2 KPI grid
// ─────────────────────────────────────────────

class _KpiSkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.35,
      children: [
        for (int i = 0; i < 4; i++)
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderSoft),
            ),
            padding: EdgeInsets.all(15.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 72.w, height: 10.h, radius: 4),
                SizedBox(height: 12.h),
                ShimmerBox(width: 48.w, height: 27.h, radius: 4),
                SizedBox(height: 8.h),
                ShimmerBox(width: 90.w, height: 10.h, radius: 4),
              ],
            ),
          ),
      ],
    );
  }
}
