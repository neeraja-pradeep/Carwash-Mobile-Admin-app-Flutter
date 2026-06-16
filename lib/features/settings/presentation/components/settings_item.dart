import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../../../../core/widgets/app_icons.dart';

/// A single row in a settings group card.
///
/// Mirrors the `Item` component in `screen_settings.jsx`. Shows an icon box
/// on the left, title + optional subtitle in the middle, and either the
/// provided [right] widget or a chevron when [onTap] is set. Set [danger] for
/// the destructive (Logout) style.
class SettingsItem extends StatelessWidget {
  const SettingsItem({
    required this.icon,
    required this.title,
    this.sub,
    this.right,
    this.onTap,
    this.last = false,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? sub;

  /// Overrides the trailing chevron. Pass a [Switch], [Text], etc.
  final Widget? right;
  final VoidCallback? onTap;

  /// When true, no bottom divider is drawn (last item in the group).
  final bool last;

  /// Red danger style (logout row).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final iconBg = danger ? AppColors.redBg : AppColors.bgPage;
    final iconFg = danger ? AppColors.redFg : AppColors.fgSecondary;
    final titleColor = danger ? AppColors.redFg : AppColors.fgPrimary;

    final content = Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: iconFg),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.figtree(
                  size: 14,
                  weight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              if (sub != null)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        right ??
            (onTap != null
                ? Icon(AppIcons.chevRight, size: 18.sp, color: AppColors.fgMuted)
                : const SizedBox.shrink()),
      ],
    );

    final decorated = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: content,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: decorated,
      ),
    );
  }
}
