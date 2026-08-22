import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_fab.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/empty_state.dart';
import 'package:new_flutter_project/core/widgets/list_controls.dart';
import 'package:new_flutter_project/core/widgets/search_field.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';

import '../../application/providers/service_requests_providers.dart';
import '../../domain/entities/service_request.dart';
import 'sr_filter_sheet.dart';
import 'sr_request_card.dart';

/// Sort options for the service-requests list.
const List<SortOption> _kSrSortOptions = [
  ('recent', 'Most Recent'),
  ('upcoming', 'Upcoming First'),
  ('status', 'By Status'),
];

/// Self-contained service-requests list widget — used as the FIRST segment of
/// the Bookings screen.
///
/// Includes its own search bar, active filter chips, [ListControls], skeleton /
/// empty / error states, request cards and a create FAB.
class ServiceRequestsList extends ConsumerWidget {
  const ServiceRequestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(serviceRequestsFilterProvider);
    final filterCtrl = ref.read(serviceRequestsFilterProvider.notifier);
    final filteredAsync = ref.watch(filteredServiceRequestsProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Search bar.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: SearchField(
                value: filter.query,
                onChanged: (q) => filterCtrl.setQuery(q),
                hintText: 'Search ID, name, or phone',
              ),
            ),

            // Active filter chips.
            if (filter.kind != null || filter.status != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (filter.kind != null)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: AppChip(
                            label: filter.kind!.label,
                            active: true,
                            removable: true,
                            onRemove: () => filterCtrl.removeKind(),
                          ),
                        ),
                      if (filter.status != null)
                        AppChip(
                          label: filter.status!.label,
                          active: true,
                          removable: true,
                          onRemove: () => filterCtrl.removeStatus(),
                        ),
                    ],
                  ),
                ),
              ),

            // List content.
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(serviceRequestsProvider);
                  await ref.read(serviceRequestsProvider.future);
                },
                child: filteredAsync.when(
                  loading: () => ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 96.h),
                    children: [
                      const SkeletonCard(),
                      SizedBox(height: 12.h),
                      const SkeletonCard(),
                      SizedBox(height: 12.h),
                      const SkeletonCard(),
                    ],
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error loading requests',
                      style: AppText.figtree(
                        size: 14,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: EmptyState(
                              icon: AppIcons.inbox,
                              title: 'No requests match',
                              body: filter.activeFilterCount > 0 ||
                                      filter.query.isNotEmpty
                                  ? 'Try adjusting your search or filters.'
                                  : 'New driver hire and inspection requests will appear here.',
                              actionLabel: filter.activeFilterCount > 0 ||
                                      filter.query.isNotEmpty
                                  ? 'Reset filters'
                                  : null,
                              onAction: () => filterCtrl.reset(),
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: ListControls(
                              count: list.length,
                              noun: 'request',
                              onFilter: () => _openFilterSheet(context, ref),
                              filterCount: filter.activeFilterCount,
                              sort: filter.sort,
                              sortOptions: _kSrSortOptions,
                              onSort: (s) => filterCtrl.setSort(s),
                            ),
                          );
                        }
                        final r = list[i - 1];
                        return _RequestCardWrapper(request: r);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // Create FAB — bottom-right, sitting just above the bottom nav
        // (matches the Carwash segment's FAB offset).
        Positioned(
          right: 18.w,
          bottom: 28.h,
          child: AppFab(
            semanticLabel: 'New service request',
            onPressed: () => _openCreateSheet(context),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilterSheet(BuildContext context, WidgetRef ref) async {
    // Seed draft from committed filter.
    ref.read(serviceRequestsFilterDraftProvider.notifier).state =
        ref.read(serviceRequestsFilterProvider);
    await showAppBottomSheet<void>(
      context: context,
      title: 'Filter requests',
      builder: (sheetCtx) => SrFilterSheet(sheetContext: sheetCtx),
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    await showAppBottomSheet<void>(
      context: context,
      title: 'New request',
      maxHeightFactor: 0.48,
      builder: (sheetCtx) => _CreateTypeSheet(sheetContext: sheetCtx),
    );
  }
}

/// "New request" type picker sheet: Driver Hire or Inspection.
class _CreateTypeSheet extends StatelessWidget {
  const _CreateTypeSheet({required this.sheetContext});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Log a phone-in request on the customer's behalf. "
          "You'll call to confirm fee and timing.",
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        _TypeTile(
          icon: AppIcons.car,
          label: 'Driver hire',
          subtitle: 'Hire a driver hourly or by day',
          onTap: () {
            Navigator.of(sheetContext).pop();
            context.push(Routes.newServiceRequest(SrKind.driver));
          },
        ),
        SizedBox(height: 10.h),
        _TypeTile(
          icon: AppIcons.search,
          label: 'Vehicle inspection',
          subtitle: 'Pre-purchase / pre-sale check',
          onTap: () {
            Navigator.of(sheetContext).pop();
            context.push(Routes.newServiceRequest(SrKind.inspection));
          },
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.sp, color: AppColors.fgSecondary),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.figtree(size: 14.5, weight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevRight,
              size: 18.sp,
              color: AppColors.fgTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a request card using the assignee name the list API already
/// provides (`assignee_name`), carried on [ServiceRequest.assigneeName].
class _RequestCardWrapper extends ConsumerWidget {
  const _RequestCardWrapper({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrRequestCard(
      request: request,
      assigneeName: request.assigneeName,
      onTap: () => context.push(Routes.serviceRequestDetail(request.id)),
    );
  }
}
