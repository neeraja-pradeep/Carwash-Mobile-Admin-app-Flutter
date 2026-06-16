import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import 'app_button.dart';
import 'app_icons.dart';

/// The brand-yellow floating action button (gradient + glow), 56×56 with an
/// 18px radius. Place it inside a [Stack] via [Positioned]; the standard offset
/// (`right: 18`, `bottom: 96`) clears the bottom nav — use a smaller bottom for
/// screens without a nav bar.
class AppFab extends StatelessWidget {
  const AppFab({
    required this.onPressed,
    this.icon = AppIcons.plus,
    this.semanticLabel = 'Add',
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56.r,
          height: 56.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.brandYellowLight,
                AppColors.brandYellow,
                AppColors.brandYellowDeep,
              ],
              stops: [0, 0.55, 1],
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x99D6B112),
                offset: Offset(0, 10.h),
                blurRadius: 24.r,
                spreadRadius: -6.r,
              ),
              BoxShadow(
                color: const Color(0x2E14141E),
                offset: Offset(0, 2.h),
                blurRadius: 6.r,
              ),
            ],
          ),
          child: Icon(icon, size: 26.sp, color: AppColors.fgPrimary),
        ),
      ),
    );
  }

  /// The standard FAB gradient, reused by other CTAs when needed.
  static LinearGradient get gradient => AppButton.brandGradient;
}
