import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/team_member.dart';

import '../../application/providers/service_requests_providers.dart';
import '../../domain/entities/service_request.dart';

/// Bottom-sheet content for assigning a driver or inspector to a service
/// request.
///
/// Mirrors `SrAssignSheet` in `screen_servicereq.jsx`. Busy assignees
/// (those on a job or on another active request) are shown disabled.
class SrAssignSheet extends ConsumerWidget {
  const SrAssignSheet({
    required this.kind,
    required this.currentRequestId,
    required this.currentAssigneeId,
    required this.sheetContext,
    required this.onPick,
    super.key,
  });

  final SrKind kind;
  final String currentRequestId;
  final String? currentAssigneeId;
  final BuildContext sheetContext;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(serviceRequestsProvider);
    final driversAsync = ref.watch(fieldDriversProvider);
    final inspectorsAsync = ref.watch(inspectorsProvider);

    // Resolve the pool as List<dynamic> based on kind.
    final AsyncValue<List<dynamic>> poolAsync = kind == SrKind.driver
        ? driversAsync.whenData((list) => list.cast<dynamic>())
        : inspectorsAsync.whenData((list) => list.cast<dynamic>());

    return poolAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (pool) {
        return requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (requests) {
            return _AssignSheetBody(
              kind: kind,
              pool: pool,
              currentRequestId: currentRequestId,
              currentAssigneeId: currentAssigneeId,
              sheetContext: sheetContext,
              onPick: onPick,
              activeRequests: requests
                  .where((r) =>
                      r.status == ServiceRequestStatus.assigned ||
                      r.status == ServiceRequestStatus.inProgress)
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _AssignSheetBody extends StatelessWidget {
  const _AssignSheetBody({
    required this.kind,
    required this.pool,
    required this.currentRequestId,
    required this.currentAssigneeId,
    required this.sheetContext,
    required this.onPick,
    required this.activeRequests,
  });

  final SrKind kind;
  final List<dynamic> pool;
  final String currentRequestId;
  final String? currentAssigneeId;
  final BuildContext sheetContext;
  final ValueChanged<String> onPick;
  final List<ServiceRequest> activeRequests;

  bool _isBusy(String id) {
    // For field drivers: check currentJob.
    if (kind == SrKind.driver) {
      final fd = pool.firstWhere(
        (p) => (p as FieldDriver).id == id,
        orElse: () => null,
      );
      if (fd is FieldDriver && fd.onJob && fd.id != currentAssigneeId) {
        return true;
      }
    }
    // Check active service requests.
    return activeRequests.any(
      (r) => r.assigneeId == id && r.id != currentRequestId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Only available ${kind == SrKind.driver ? 'drivers' : 'inspectors'} '
          'can be assigned. Those on a job at this time are shown as unavailable.',
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        for (final p in pool) _AssigneeRow(
          id: _getId(p),
          name: _getName(p),
          role: _getRole(p),
          isActive: _getId(p) == currentAssigneeId,
          isBusy: _isBusy(_getId(p)),
          onTap: () {
            onPick(_getId(p));
            Navigator.of(sheetContext).pop();
          },
        ),
      ],
    );
  }

  String _getId(dynamic p) {
    if (p is FieldDriver) return p.id;
    if (p is TeamMember) return p.id;
    return '';
  }

  String _getName(dynamic p) {
    if (p is FieldDriver) return p.name;
    if (p is TeamMember) return p.name;
    return '';
  }

  String _getRole(dynamic p) {
    if (p is FieldDriver) return p.role;
    if (p is TeamMember) return p.role;
    return '';
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    required this.isBusy,
    required this.onTap,
  });

  final String id;
  final String name;
  final String role;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: isBusy ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isBusy ? 0.55 : 1.0,
          child: Container(
            padding: EdgeInsets.all(13.r),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brandYellow : AppColors.bgCard,
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(
                color: isActive
                    ? AppColors.brandYellowDeep
                    : AppColors.borderSoft,
              ),
            ),
            child: Row(
              children: [
                Avatar(name: name, size: 40),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppText.figtree(
                            size: 14.5,
                            weight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(text: name),
                            TextSpan(
                              text: ' · $role',
                              style: AppText.figtree(
                                size: 12,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          if (isBusy)
                            Icon(
                              AppIcons.clock,
                              size: 12.sp,
                              color: AppColors.amberFg,
                            )
                          else
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                color: AppColors.greenFg,
                                shape: BoxShape.circle,
                              ),
                            ),
                          SizedBox(width: 5.w),
                          Text(
                            isBusy ? 'On a job · unavailable' : 'Available',
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w500,
                              color: isBusy
                                  ? AppColors.amberFg
                                  : AppColors.fgTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Icon(
                    AppIcons.check,
                    size: 20.sp,
                    color: AppColors.fgPrimary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
