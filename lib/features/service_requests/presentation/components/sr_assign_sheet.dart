import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';

import '../../application/providers/service_requests_providers.dart';
import '../../infrastructure/models/driver_inspection_detail_response_model.dart';

/// Bottom-sheet content for assigning a driver or inspector to a service
/// request.
///
/// Fetches available workers from the API endpoint with server-authoritative
/// availability information. Workers are pre-sorted by availability and name.
class SrAssignSheet extends ConsumerWidget {
  const SrAssignSheet({
    required this.requestId,
    required this.currentAssigneeId,
    required this.sheetContext,
    required this.onPick,
    super.key,
  });

  final int requestId;
  final String? currentAssigneeId;
  final BuildContext sheetContext;

  /// Called with the picked assignee's id and display name.
  final void Function(String id, String name) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch available workers from API
    final workersAsync = ref.watch(assignableWorkersProvider(requestId));

    return workersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error loading workers: $e',
              style: AppText.figtree(
                size: 12,
                color: AppColors.fgTertiary,
              ),
            ),
          ],
        ),
      ),
      data: (response) {
        return _AssignSheetBody(
          workers: response.items,
          currentAssigneeId: currentAssigneeId,
          sheetContext: sheetContext,
          onPick: onPick,
        );
      },
    );
  }
}

class _AssignSheetBody extends StatelessWidget {
  const _AssignSheetBody({
    required this.workers,
    required this.currentAssigneeId,
    required this.sheetContext,
    required this.onPick,
  });

  final List<AssignableWorkerModel> workers;
  final String? currentAssigneeId;
  final BuildContext sheetContext;
  final void Function(String id, String name) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Only available workers can be assigned. Those on a job at this time are shown as unavailable.',
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        if (workers.isEmpty)
          Text(
            'No workers available',
            style: AppText.figtree(
              size: 12,
              color: AppColors.fgTertiary,
            ),
          )
        else
          for (final worker in workers)
            _AssigneeRow(
              id: worker.id.toString(),
              name: worker.name,
              role: worker.title,
              rating: worker.rating,
              isActive: worker.id.toString() == currentAssigneeId,
              isAvailable: worker.available,
              onTap: () {
                onPick(worker.id.toString(), worker.name);
                Navigator.of(sheetContext).pop();
              },
            ),
      ],
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.isActive,
    required this.isAvailable,
    required this.onTap,
  });

  final String id;
  final String name;
  final String role;
  final double? rating;
  final bool isActive;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: isAvailable ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isAvailable ? 1.0 : 0.55,
          child: Container(
            padding: EdgeInsets.all(13.r),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brandYellow : AppColors.bgCard,
              borderRadius: BorderRadius.circular(13.r),
              border: Border.all(
                color:
                    isActive ? AppColors.brandYellowDeep : AppColors.borderSoft,
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
                          if (!isAvailable)
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
                            isAvailable ? 'Available' : 'On a job · unavailable',
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w500,
                              color: isAvailable
                                  ? AppColors.fgTertiary
                                  : AppColors.amberFg,
                            ),
                          ),
                          if (rating != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '★ ${rating!.toStringAsFixed(1)}',
                              style: AppText.figtree(
                                size: 11,
                                weight: FontWeight.w500,
                                color: AppColors.fgTertiary,
                              ),
                            ),
                          ],
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
