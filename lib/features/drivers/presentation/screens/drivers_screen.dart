import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_fab.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/empty_state.dart';
import 'package:new_flutter_project/core/widgets/list_controls.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';

import '../../application/providers/drivers_providers.dart';
import '../../domain/entities/field_driver.dart';
import '../../domain/entities/team_member.dart';
import '../components/driver_card.dart';
import '../components/drivers_filter_sheet.dart';

/// Admin Drivers & Inspectors list — bottom-nav tab (NO back button in TopBar).
///
/// Segmented control: Drivers | Inspectors.
/// Drivers: filterable list of [FieldDriver] with status pills + license column.
/// Inspectors: simple list of [TeamMember].
/// FAB: "Hire Driver" or "Add Inspector" → [Routes.hireDriver].
class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seg = ref.watch(driversSegmentProvider);
    final filter = ref.watch(driversFilterProvider);
    final filtered = ref.watch(filteredFieldDriversProvider);
    final inspectorsAsync = ref.watch(inspectorsProvider);

    final isDrivers = seg == 'drivers';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // TopBar — no back button (bottom-nav tab)
                TopBar(
                  title: 'Team',
                  subtitle: 'Drivers & roles',
                ),

                // Segmented control
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegBtn(
                          label: 'Drivers',
                          active: isDrivers,
                          onTap: () {
                            ref.read(driversSegmentProvider.notifier).state =
                                'drivers';
                            ref.read(driversFilterProvider.notifier).reset();
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _SegBtn(
                          label: 'Inspectors',
                          active: !isDrivers,
                          onTap: () {
                            ref.read(driversSegmentProvider.notifier).state =
                                'inspectors';
                            ref.read(driversFilterProvider.notifier).reset();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Active filter chips
                if (isDrivers && filter.activeCount > 0) _ActiveChips(),

                // List
                Expanded(
                  child: isDrivers
                      ? _DriversList(
                          filtered: filtered,
                          filterCount: filter.activeCount,
                          onFilter: () =>
                              showDriversFilterSheet(context, ref),
                          onClearFilter: () =>
                              ref.read(driversFilterProvider.notifier).reset(),
                          onTap: (id) =>
                              context.push(Routes.driverDetail(id)),
                        )
                      : _InspectorsList(
                          inspectorsAsync: inspectorsAsync,
                        ),
                ),
              ],
            ),

            // FAB
            Positioned(
              right: 18.w,
              bottom: 96.h,
              child: AppFab(
                onPressed: () => context.push(Routes.hireDriver),
                icon: AppIcons.plus,
                semanticLabel: isDrivers ? 'Hire Driver' : 'Add Inspector',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented button ──────────────────────────────────────────────────────────

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color:
                active ? AppColors.brandYellowDeep : AppColors.borderDefault,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Active chips ──────────────────────────────────────────────────────────────

class _ActiveChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(driversFilterProvider);
    final controller = ref.read(driversFilterProvider.notifier);

    if (filter.status == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(
              label: filter.status!.label,
              active: true,
              removable: true,
              onRemove: () => controller.setStatus(null),
            ),
            SizedBox(width: 8.w),
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

// ── Drivers list ──────────────────────────────────────────────────────────────

class _DriversList extends StatelessWidget {
  const _DriversList({
    required this.filtered,
    required this.filterCount,
    required this.onFilter,
    required this.onClearFilter,
    required this.onTap,
  });

  final AsyncValue<List<FieldDriver>> filtered;
  final int filterCount;
  final VoidCallback onFilter;
  final VoidCallback onClearFilter;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return filtered.when(
      loading: () => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (_, __) => Center(
        child: Text(
          'Error loading drivers',
          style: AppText.figtree(
            size: 14,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ),
      data: (drivers) {
        if (drivers.isEmpty) {
          return EmptyState(
            icon: AppIcons.car,
            title: 'No drivers match',
            body: 'Try clearing the filter.',
            actionLabel: 'Reset',
            onAction: onClearFilter,
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
          itemCount: drivers.length + 1,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListControls(
                count: drivers.length,
                noun: 'driver',
                onFilter: onFilter,
                filterCount: filterCount,
              );
            }
            final driver = drivers[index - 1];
            return DriverCard(
              driver: driver,
              onTap: () => onTap(driver.id),
            );
          },
        );
      },
    );
  }
}

// ── Inspectors list ───────────────────────────────────────────────────────────

class _InspectorsList extends StatelessWidget {
  const _InspectorsList({required this.inspectorsAsync});

  final AsyncValue<List<TeamMember>> inspectorsAsync;

  @override
  Widget build(BuildContext context) {
    return inspectorsAsync.when(
      loading: () => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: 2,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (_, __) => Center(
        child: Text(
          'Error loading inspectors',
          style: AppText.figtree(
            size: 14,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ),
      data: (inspectors) {
        if (inspectors.isEmpty) {
          return const EmptyState(
            title: 'No inspectors',
            body: 'Add an inspector to get started.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
          itemCount: inspectors.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, index) {
            final inspector = inspectors[index];
            return _InspectorCard(inspector: inspector);
          },
        );
      },
    );
  }
}

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({required this.inspector});

  final TeamMember inspector;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Avatar(name: inspector.name, size: 42),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inspector.name,
                  style: AppText.figtree(
                    size: 14.5,
                    weight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${inspector.role} · ${inspector.phone}',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: inspector.active
                ? DriverStatus.active.label
                : DriverStatus.suspended.label,
            tone: inspector.active
                ? DriverStatus.active.tone
                : DriverStatus.suspended.tone,
          ),
        ],
      ),
    );
  }
}
