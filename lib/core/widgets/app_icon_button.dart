import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// A 40×40 borderless icon button with an optional red count badge
/// (e.g. the notification bell). Mirrors `IconBtn` in `ui.jsx`.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    this.onTap,
    this.semanticLabel,
    this.badge,
    this.iconSize = 23,
    this.color = AppColors.fgPrimary,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? badge;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: iconSize.sp, color: color),
              if (badge != null)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 16.w),
                    height: 16.h,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      badge!,
                      style: AppText.figtree(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.fgOnDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
