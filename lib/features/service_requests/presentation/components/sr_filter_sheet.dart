import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/status/service_request_status.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';

import '../../application/providers/service_requests_providers.dart';
import '../../application/states/service_requests_filter_state.dart';
import '../../domain/entities/service_request.dart';

/// Bottom-sheet content for filtering service requests by kind and status.
///
/// Rendered inside [showAppBottomSheet]; accepts the sheet's [BuildContext]
/// for popping.
class SrFilterSheet extends ConsumerWidget {
  const SrFilterSheet({required this.sheetContext, super.key});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(serviceRequestsFilterDraftProvider);
    final notifier = ref.read(serviceRequestsFilterDraftProvider.notifier);

    void toggleKind(SrKind k) {
      notifier.state = draft.kind == k
          ? draft.copyWith(clearKind: true)
          : draft.copyWith(kind: k);
    }

    void toggleStatus(ServiceRequestStatus s) {
      notifier.state = draft.status == s
          ? draft.copyWith(clearStatus: true)
          : draft.copyWith(status: s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Service type', style: AppText.eyebrow),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            AppChip(
              label: 'Driver Hire',
              active: draft.kind == SrKind.driver,
              onTap: () => toggleKind(SrKind.driver),
            ),
            AppChip(
              label: 'Inspection',
              active: draft.kind == SrKind.inspection,
              onTap: () => toggleKind(SrKind.inspection),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text('Status', style: AppText.eyebrow),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final s in ServiceRequestStatus.values)
              AppChip(
                label: s.label,
                active: draft.status == s,
                onTap: () => toggleStatus(s),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Reset',
                kind: AppButtonKind.secondary,
                full: true,
                onPressed: () {
                  notifier.state = const ServiceRequestsFilterState();
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppButton(
                label: 'Apply',
                full: true,
                onPressed: () {
                  ref
                      .read(serviceRequestsFilterProvider.notifier)
                      .apply(draft);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
