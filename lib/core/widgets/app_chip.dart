import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'app_icons.dart';

/// A pill chip used for filters and selectable options. Active chips fill with
/// brand yellow; [removable] chips show a trailing × (active-filter chips).
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.onTap,
    this.active = false,
    this.removable = false,
    this.onRemove,
    this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool removable;
  final VoidCallback? onRemove;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: removable
            ? EdgeInsets.fromLTRB(12.w, 7.h, 8.w, 7.h)
            : EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.bgCard,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: active ? AppColors.brandYellowDeep : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, SizedBox(width: 6.w)],
            // Flexible, not a bare Text: a chip laid out in a Wrap is given the
            // Wrap's full width as its constraint, so a label longer than one
            // line (e.g. "Cancellation by customer" on a narrow phone) would
            // otherwise overflow the pill rather than shrink inside it.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.figtree(
                  size: 13,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.fgPrimary,
                ),
              ),
            ),
            if (removable) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  AppIcons.close,
                  size: 15.sp,
                  color: AppColors.fgPrimary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
