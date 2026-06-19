import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/error/error_view.dart';
import 'package:new_flutter_project/core/status/booking_status.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_fab.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/empty_state.dart';
import 'package:new_flutter_project/core/widgets/list_controls.dart';
import 'package:new_flutter_project/core/widgets/search_field.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/features/service_requests/presentation/components/service_requests_list.dart';

import '../../application/providers/bookings_providers.dart';
import '../../application/states/bookings_filter_state.dart';
import '../components/booking_card.dart';
import '../components/bookings_filter_sheet.dart';

/// The Bookings tab screen.
///
/// Contains a segment toggle ("Driver & Inspection" | "Carwash"). The
/// Driver & Inspection segment renders [ServiceRequestsList]; the Carwash
/// segment renders the full booking list with search, filter sheet, sort,
/// active chips, skeleton/empty/error states and a "New Booking" FAB.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(bookingsSegmentProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(title: 'Bookings', subtitle: 'Today · 29 May 2026'),

            // Segment toggle
            Container(
              color: AppColors.bgCard,
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'Driver & Inspection',
                    selected: segment == 0,
                    onTap: () =>
                        ref.read(bookingsSegmentProvider.notifier).state = 0,
                  ),
                  SizedBox(width: 8.w),
                  _SegmentButton(
                    label: 'Carwash',
                    selected: segment == 1,
                    onTap: () =>
                        ref.read(bookingsSegmentProvider.notifier).state = 1,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: IndexedStack(
                index: segment,
                children: [
                  // Segment 0: Service requests list
                  const ServiceRequestsList(),

                  // Segment 1: Carwash list
                  const _CarwashBookingsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment toggle button ─────────────────────────────────────────────────────

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandYellow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? AppColors.brandYellowDeep
                  : AppColors.borderDefault,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Carwash bookings list ─────────────────────────────────────────────────────

class _CarwashBookingsList extends ConsumerWidget {
  const _CarwashBookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bookingsFilterProvider);
    final controller = ref.read(bookingsFilterProvider.notifier);
    final filtered = ref.watch(filteredBookingsProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Search bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSoft),
                ),
              ),
              child: SearchField(
                value: filter.query,
                hintText: 'Search ID, name, or phone',
                onChanged: controller.setQuery,
              ),
            ),

            // Active filter chips
            if (filter.activeCount > 0)
              _ActiveChips(filter: filter, controller: controller),

            // Body
            Expanded(
              child: filtered.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => ErrorView(
                  onRetry: () => ref.invalidate(bookingsProvider),
                ),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.car,
                      title: 'No bookings match',
                      body: filter.query.isNotEmpty || filter.activeCount > 0
                          ? 'Try clearing your search or filters.'
                          : "Today's bookings will appear here as they come in.",
                      actionLabel:
                          filter.query.isNotEmpty || filter.activeCount > 0
                              ? 'Reset filters'
                              : null,
                      onAction: () {
                        controller.reset();
                      },
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemCount: bookings.length + 2, // controls + items + spacer
                    separatorBuilder: (_, i) =>
                        i == 0 ? const SizedBox.shrink() : SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListControls(
                          count: bookings.length,
                          noun: 'booking',
                          onFilter: () =>
                              showBookingsFilterSheet(context, ref),
                          filterCount: filter.activeCount,
                          sort: filter.sort,
                          sortOptions: _sortOptions,
                          onSort: controller.setSort,
                        );
                      }
                      if (index == bookings.length + 1) {
                        return SizedBox(height: 84.h);
                      }
                      final booking = bookings[index - 1];
                      return BookingCard(
                        booking: booking,
                        onTap: () =>
                            context.push(Routes.bookingDetail(booking.id)),
                        onAssign: () {
                          AppToast.show(
                            context,
                            'Assigned to you (Anand)',
                            actionLabel: 'Undo',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // FAB
        Positioned(
          right: 18.w,
          bottom: 96.h,
          child: AppFab(
            onPressed: () => context.push(Routes.newBooking),
            icon: AppIcons.plus,
            semanticLabel: 'New booking',
          ),
        ),
      ],
    );
  }

  static const List<SortOption> _sortOptions = [
    ('recent', 'Most recent'),
    ('oldest', 'Oldest first'),
    ('amount_hi', 'Amount: high → low'),
    ('amount_lo', 'Amount: low → high'),
    ('name', 'Customer A–Z'),
  ];
}

// ── Active chips row ──────────────────────────────────────────────────────────

class _ActiveChips extends StatelessWidget {
  const _ActiveChips({
    required this.filter,
    required this.controller,
  });

  final BookingsFilterState filter;
  final BookingsFilterController controller;

  static const List<(String, String)> _datePresets = [
    ('today', 'Today'),
    ('yesterday', 'Yesterday'),
    ('last7', 'Last 7 days'),
    ('month', 'This Month'),
    ('custom', 'Custom'),
  ];

  static const List<(String, String)> _daypartLabels = [
    ('morning', 'Morning'),
    ('afternoon', 'Afternoon'),
    ('evening', 'Evening'),
  ];

  static const List<(String, String)> _assignLabels = [
    ('me', 'Assigned to me'),
    ('cofounder', 'Co-founder'),
    ('unassigned', 'Unassigned'),
  ];

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.date != 'today') {
      final label = _datePresets
          .firstWhere(
            (d) => d.$1 == filter.date,
            orElse: () => (filter.date, filter.date),
          )
          .$2;
      chips.add(AppChip(
        label: label,
        active: true,
        removable: true,
        onRemove: controller.removeDate,
      ));
    }

    if (filter.daypart != null) {
      final label = _daypartLabels
          .firstWhere(
            (d) => d.$1 == filter.daypart,
            orElse: () => (filter.daypart!, filter.daypart!),
          )
          .$2;
      chips.add(AppChip(
        label: label,
        active: true,
        removable: true,
        onRemove: controller.removeDaypart,
      ));
    }

    for (final s in filter.statuses) {
      final statusLabel = bookingStatusFromKey(s).label;
      chips.add(AppChip(
        label: statusLabel,
        active: true,
        removable: true,
        onRemove: () => controller.removeStatus(s),
      ));
    }

    for (final sh in filter.shops) {
      chips.add(AppChip(
        label: sh,
        active: true,
        removable: true,
        onRemove: () => controller.removeShop(sh),
      ));
    }

    if (filter.assign != null) {
      final label = _assignLabels
          .firstWhere(
            (a) => a.$1 == filter.assign,
            orElse: () => (filter.assign!, filter.assign!),
          )
          .$2;
      chips.add(AppChip(
        label: label,
        active: true,
        removable: true,
        onRemove: controller.removeAssign,
      ));
    }

    return Container(
      width: double.infinity,
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[chip, SizedBox(width: 8.w)],
            GestureDetector(
              onTap: controller.reset,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Text(
                  'Clear all',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.fgSecondary,
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
