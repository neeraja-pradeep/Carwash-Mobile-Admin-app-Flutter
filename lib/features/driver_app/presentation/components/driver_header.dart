import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar.dart';
import '../../application/providers/driver_app_providers.dart';

/// Persistent driver-app header: the signed-in driver's avatar + first
/// name/role and the Online/Offline toggle pill. Rendered once in
/// [DriverShell] above the tab content so it stays put across
/// Today / Schedule / Earnings / Profile — mirroring the shared header in the
/// `DriverApp` shell of `screen_driver_app.jsx` (rendered above the tab switch).
class DriverHeader extends ConsumerWidget {
  const DriverHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(signedInDriverProvider);
    final isOnline = ref.watch(driverOnlineProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          driverAsync.when(
            loading: () => Container(
              width: 40.r,
              height: 40.r,
              decoration: const BoxDecoration(
                color: AppColors.avatarBg,
                shape: BoxShape.circle,
              ),
            ),
            error: (_, __) => const Avatar(name: 'Manoj Kumar'),
            data: (driver) => Avatar(name: driver?.name ?? 'Driver', size: 40),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driverAsync.maybeWhen(
                    data: (d) => d?.name.split(' ').first ?? 'Driver',
                    orElse: () => 'Manoj',
                  ),
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  driverAsync.maybeWhen(
                    data: (d) => d?.role ?? 'Driver',
                    orElse: () => 'Wash driver',
                  ),
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Online / Offline toggle — writes the shared provider and fires the
          // same toasts as the JSX ("You're online" / "You're now offline").
          GestureDetector(
            onTap: () {
              ref.read(driverOnlineProvider.notifier).state = !isOnline;
              AppToast.show(
                context,
                isOnline ? "You're now offline" : "You're online",
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36.h,
              padding: EdgeInsets.symmetric(horizontal: 13.w),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.greenBg : AppColors.bgCard,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: isOnline ? AppColors.greenFg : AppColors.borderDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.greenFg : AppColors.fgMuted,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color:
                          isOnline ? AppColors.greenFg : AppColors.fgSecondary,
                    ),
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
