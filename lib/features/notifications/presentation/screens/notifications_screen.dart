import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_controls.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/notifications_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../components/notif_row.dart';

/// Notifications list screen.
///
/// Mirrors `NotificationsScreen` in `screen_notifications.jsx` (lines 32–88).
/// All / Unread filter, mark-all-read action, tap deep-links, skeleton loading.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final notificationsAsync = ref.watch(allNotificationsProvider);
    final filter = ref.watch(notificationsFilterProvider);
    final filterController = ref.read(notificationsFilterProvider.notifier);
    final repository = ref.read(notificationsRepositoryProvider);

    final unreadCount = unreadAsync.valueOrNull ?? 0;

    void markAllRead() async {
      await repository.markAllAsRead();
      // Invalidate the unread count and notifications to refresh
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationsProvider);
      if (context.mounted) {
        AppToast.show(context, 'All marked as read');
      }
    }

    void openNotification(AppNotification n) async {
      // Mark as read on API
      await repository.markAsRead(n.id);
      // Invalidate to refresh
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationsProvider);

      // Deep-link
      if (n.refBooking != null) {
        if (context.mounted) {
          context.push(Routes.bookingDetail(n.refBooking.toString()));
        }
      } else if (n.refDiBooking != null) {
        if (context.mounted) {
          context.push(Routes.bookings); // Navigate to bookings (DI requests)
        }
      } else {
        if (context.mounted) {
          AppToast.show(context, n.title);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Notifications',
              subtitle:
                  unreadCount > 0 ? '$unreadCount unread' : 'All caught up',
              onBack: () => context.pop(),
              actions: [
                if (unreadCount > 0)
                  GestureDetector(
                    onTap: markAllRead,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: 'Mark all read',
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          AppIcons.check,
                          size: 22.sp,
                          color: AppColors.fgPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const _SkeletonList(),
                error: (_, __) => const Center(
                  child: Text('Failed to load notifications'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.bell,
                      title: filter == 'unread'
                          ? 'No unread notifications'
                          : 'No notifications',
                      body: filter == 'unread'
                          ? "You're all caught up."
                          : 'Activity across bookings, refunds and shops will show here.',
                      actionLabel: filter == 'unread' ? 'Show all' : null,
                      onAction: filter == 'unread'
                          ? () => filterController.state = 'all'
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                      await ref.read(notificationsProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                      children: [
                        ListControls(
                          count: items.length,
                          noun: 'notification',
                          onFilter: () => _showFilterSheet(
                            context,
                            filter: filter,
                            onChanged: (v) => filterController.state = v,
                          ),
                          filterCount: filter == 'unread' ? 1 : 0,
                        ),
                        // Notif rows
                        Column(
                          children: [
                            for (final n in items)
                              NotifRow(
                                key: ValueKey(n.id),
                                notification: n,
                                onTap: () => openNotification(n),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showFilterSheet(
    BuildContext context, {
    required String filter,
    required ValueChanged<String> onChanged,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Filter notifications',
      maxHeightFactor: 0.5,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in [
            ('all', 'All notifications'),
            ('unread', 'Unread only')
          ])
            GestureDetector(
              onTap: () {
                onChanged(option.$1);
                Navigator.of(sheetCtx).pop();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      option.$2,
                      style: AppText.figtree(
                        size: 14.5,
                        weight: option.$1 == filter
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (option.$1 == filter)
                      Icon(
                        AppIcons.check,
                        size: 19.sp,
                        color: AppColors.brandYellowDeep,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        for (var i = 0; i < 4; i++) ...[
          const SkeletonCard(),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }
}
