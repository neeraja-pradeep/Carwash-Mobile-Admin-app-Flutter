import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';

/// A KPI metric tile — mirrors `KpiTile` in `screen_dashboard.jsx`.
///
/// When [alert] is true the tile switches to a yellow brand-background state
/// (used for Overdue and open Hire Requests). [sub] is a small descriptor line
/// below the big value; pass [subColor] to tint it (e.g. amber for refund amt).
class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.eyebrow,
    required this.value,
    required this.sub,
    required this.icon,
    required this.onTap,
    this.alert = false,
    this.subColor,
    super.key,
  });

  final String eyebrow;
  final String value;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  final bool alert;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    final bg = alert ? AppColors.brandYellow : AppColors.bgCard;
    final border = alert ? AppColors.brandYellowDeep : AppColors.borderSoft;
    final eyebrowColor = alert ? const Color(0x99000000) : AppColors.fgTertiary;
    final iconColor = alert ? AppColors.fgPrimary : AppColors.fgTertiary;
    final resolvedSubColor =
        alert ? const Color(0xB3000000) : (subColor ?? AppColors.fgTertiary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                // rgba(0,0,0,0.03) from screen_dashboard.jsx KpiTile.
                color: const Color(0x08000000),
                offset: Offset(0, 1.h),
                blurRadius: 2.r,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(15.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: AppText.figtree(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: eyebrowColor,
                          letterSpacing: 0.08 * 10.5,
                        ),
                      ),
                    ),
                    Icon(icon, size: 18.sp, color: iconColor),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 27,
                    weight: FontWeight.w800,
                    color: AppColors.fgPrimary,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                SizedBox(height: 5.h),
                // Flexible so a longer sub line (or a larger system font scale)
                // ellipsises within the fixed-height grid cell instead of
                // overflowing the tile — see the Bookings Today tile, whose
                // "N waiting · N active · N done" is the tallest sub.
                Flexible(
                  child: Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: resolvedSubColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
