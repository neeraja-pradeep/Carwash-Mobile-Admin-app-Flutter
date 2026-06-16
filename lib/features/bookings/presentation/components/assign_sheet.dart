import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_bottom_sheet.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/features/drivers/application/providers/drivers_providers.dart';

/// Opens a bottom sheet for assigning (or reassigning) a driver to a booking.
///
/// Shows founders, co-founders, and available field drivers. Drivers currently
/// on a job are shown but disabled (conflict detection).
Future<void> showAssignSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String? currentDriverId,
  required void Function(String driverId, String driverName) onPick,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Assign driver',
    maxHeightFactor: 0.72,
    builder: (_) => _AssignBody(
      currentDriverId: currentDriverId,
      onPick: onPick,
    ),
  );
}

class _AssignBody extends ConsumerWidget {
  const _AssignBody({
    required this.currentDriverId,
    required this.onPick,
  });

  final String? currentDriverId;
  final void Function(String id, String name) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundersAsync = ref.watch(foundersProvider);
    final driversAsync = ref.watch(fieldDriversProvider);

    return foundersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (founders) {
        return driversAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (drivers) {
            final rows = <_DriverRow>[];

            // Add founders first
            for (final m in founders) {
              rows.add(_DriverRow(
                id: m.id,
                name: m.name,
                subtitle: '${m.role} · ${m.phone}',
                isBusy: false,
                active: currentDriverId == m.id,
                onTap: () => onPick(m.id, m.name),
              ));
            }

            // Add field drivers
            for (final d in drivers) {
              rows.add(_DriverRow(
                id: d.id,
                name: d.name,
                subtitle: '${d.role} · ${d.phone}',
                isBusy: d.onJob && d.id != currentDriverId,
                active: currentDriverId == d.id,
                onTap: () => onPick(d.id, d.name),
              ));
            }

            return Column(
              children: rows,
            );
          },
        );
      },
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.isBusy,
    required this.active,
    required this.onTap,
  });

  final String id;
  final String name;
  final String subtitle;
  final bool isBusy;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: isBusy ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(13.r),
          decoration: BoxDecoration(
            color: active ? AppColors.brandYellow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(13.r),
            border: Border.all(
              color: active
                  ? AppColors.brandYellowDeep
                  : AppColors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: isBusy ? 0.45 : 1.0,
                child: Avatar(name: name, size: 40),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Opacity(
                  opacity: isBusy ? 0.45 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: AppText.figtree(
                              size: 14.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (isBusy) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amberBg,
                                borderRadius: BorderRadius.circular(99.r),
                              ),
                              child: Text(
                                'On job',
                                style: AppText.figtree(
                                  size: 10.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.amberFg,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: active
                              ? const Color(0xA6000000)
                              : AppColors.fgTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (active)
                Icon(
                  AppIcons.check,
                  size: 20.sp,
                  color: AppColors.fgPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
