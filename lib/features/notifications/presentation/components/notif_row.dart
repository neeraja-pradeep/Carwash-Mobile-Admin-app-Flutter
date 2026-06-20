import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../domain/entities/app_notification.dart';

/// A single notification row.
///
/// Mirrors `NotifRow` in `screen_notifications.jsx` (lines 14–29).
/// Unread items render with bgCard + soft shadow; read items are transparent.
/// Shows an unread yellow dot + bold title when unread.
class NotifRow extends StatelessWidget {
  const NotifRow({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final tone = toneFor(n.kind);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: n.unread ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: const Border(bottom: BorderSide(color: AppColors.borderSoft)),
          boxShadow: n.unread
              ? [
                  BoxShadow(
                    color: const Color(0x08000000),
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kind icon box
            Container(
              width: 38.r,
              height: 38.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(tone.icon, size: 19.sp, color: tone.fg),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row with unread dot
                  Row(
                    children: [
                      if (n.unread) ...[
                        Container(
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellowDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 7.w),
                      ],
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.figtree(
                            size: 13.5,
                            weight: n.unread ? FontWeight.w700 : FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Body
                  if (n.body != null)
                    Text(
                      n.body!,
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w400,
                        color: AppColors.fgSecondary,
                        height: 1.4,
                      ),
                    ),
                  SizedBox(height: 4.h),
                  // Time
                  Text(
                    n.time,
                    style: AppText.figtree(
                      size: 11,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
