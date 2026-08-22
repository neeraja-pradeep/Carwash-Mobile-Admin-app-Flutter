import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../application/providers/driver_home_provider.dart';

/// Persistent driver-app header: the signed-in driver's avatar + first
/// name/role and the Online/Offline toggle pill. Rendered once in
/// [DriverShell] above the tab content so it stays put across
/// Today / Schedule / Earnings / Profile — mirroring the shared header in the
/// `DriverApp` shell of `screen_driver_app.jsx` (rendered above the tab switch).
class DriverHeader extends ConsumerWidget {
  const DriverHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(driverHomeStateProvider);

    // Get user from auth state
    String role = 'Driver';
    String fullName = 'Driver';

    if (authState is AuthSuccess) {
      role = authState.user.role;
      fullName = authState.user.fullName;
    }

    // Availability survives loading/error states, so the pill reflects the
    // server's flag rather than the load status. `null` = never fetched, which
    // renders as "unknown" — showing "Offline" there is a lie the admin
    // console (reading the same flag) would contradict.
    final availability = homeState.availability;
    final isKnown = availability != null;
    final isOnline = availability?.online ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Avatar(name: fullName, size: 40),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  role,
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Online / Offline toggle — updates availability via API
          GestureDetector(
            onTap: () async {
              final ctx = context;
              if (!isKnown) {
                // Nothing to toggle from — a blind PATCH could flip the driver
                // to the state they are already in.
                AppToast.show(ctx, 'Still checking your status — try again.');
                return;
              }
              try {
                await ref
                    .read(driverHomeStateProvider.notifier)
                    .toggleAvailability(online: !isOnline);
                // Only show success toast if API call succeeds
                AppToast.show(
                  ctx,
                  isOnline ? "You're now offline" : "You're online",
                );
              } catch (e) {
                // Show error toast with message from API
                final errorMsg = e.toString().replaceFirst('Exception: ', '');
                AppToast.show(ctx, errorMsg);
              }
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
                    isKnown ? (isOnline ? 'Online' : 'Offline') : 'Checking…',
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: switch ((isKnown, isOnline)) {
                        (false, _) => AppColors.fgMuted,
                        (true, true) => AppColors.greenFg,
                        (true, false) => AppColors.fgSecondary,
                      },
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
