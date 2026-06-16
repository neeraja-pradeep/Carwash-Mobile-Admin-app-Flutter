import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_button.dart';
import 'app_icons.dart';

/// The shared empty-list state: a friendly icon, title, body and an optional
/// reset/primary action. Mirrors `EmptyState` in `ui.jsx`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.icon = AppIcons.inbox,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Icon(icon, size: 32.sp, color: AppColors.fgTertiary),
            ),
            SizedBox(height: 18.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.figtree(size: 18, weight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null) ...[
              SizedBox(height: 22.h),
              AppButton(
                label: actionLabel!,
                kind: AppButtonKind.secondary,
                size: AppButtonSize.sm,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
