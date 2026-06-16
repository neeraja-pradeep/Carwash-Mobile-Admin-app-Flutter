import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icons.dart';

/// The kind of failure an [ErrorView] represents.
enum ErrorKind { network, server }

/// Generic error state with a retry action (and Contact Support for server
/// errors). Mirrors `ErrorState` in `ui.jsx`.
class ErrorView extends StatelessWidget {
  const ErrorView({this.kind = ErrorKind.network, this.onRetry, super.key});

  final ErrorKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = kind == ErrorKind.network;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 56.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Icon(
                isNetwork ? AppIcons.cloudOff : AppIcons.alert,
                size: 32.sp,
                color: AppColors.redFg,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              isNetwork ? 'No internet' : 'Something went wrong',
              style: AppText.figtree(size: 18, weight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              isNetwork
                  ? 'Check your connection and try again.'
                  : "We couldn't load this. Please retry.",
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Retry',
                  size: AppButtonSize.sm,
                  onPressed: onRetry,
                ),
                if (!isNetwork) ...[
                  SizedBox(width: 10.w),
                  AppButton(
                    label: 'Contact Support',
                    kind: AppButtonKind.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () {},
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
