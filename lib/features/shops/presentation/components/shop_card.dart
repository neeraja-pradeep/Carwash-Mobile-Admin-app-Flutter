import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../domain/entities/shop.dart';

/// Compact star icon for ratings.
class ShopRatingStar extends StatelessWidget {
  const ShopRatingStar({this.size = 13, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.star,
      size: size.sp,
      color: AppColors.brandWarning,
    );
  }
}

/// Small status pill: Active / Inactive / Open / Closed.
class ShopMiniPill extends StatelessWidget {
  const ShopMiniPill({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    super.key,
  });

  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: BoxDecoration(
              color: fgColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns whether a shop is considered open right now (demo: based on today's
/// day of week + the shop's weekly config).
bool shopIsOpenNow(Shop s) {
  if (!s.active) return false;
  final weekdayIndex = DateTime.now().weekday; // 1=Mon … 7=Sun
  // Map Dart weekday to our weekly list index (Mon=0 … Sun=6)
  final idx = weekdayIndex - 1;
  if (idx < 0 || idx >= s.weekly.length) return false;
  return !s.weekly[idx].closed;
}

/// Formats a 24-h int hour to a label like "9:00 AM" / "8:00 PM".
String fmtHour(int h) {
  final labels = List.generate(25, (i) {
    final ap = (i < 12 || i == 24) ? 'AM' : 'PM';
    var hh = i % 12;
    if (hh == 0) hh = 12;
    return '$hh:00 $ap';
  });
  return labels[h.clamp(0, 24)];
}

/// Formats an ISO date string "2026-06-07" → "Sun, 07 Jun".
String fmtHolidayDate(String iso) {
  try {
    final d = DateTime.parse('${iso}T00:00:00');
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final wd = weekdays[d.weekday - 1];
    final mo = months[d.month - 1];
    return '$wd, ${d.day.toString().padLeft(2, '0')} $mo';
  } catch (_) {
    return iso;
  }
}

/// Shop list card — mirrors `ShopCard` in `screen_shops.jsx`.
class ShopCard extends StatelessWidget {
  const ShopCard({required this.shop, required this.onTap, super.key});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = shopIsOpenNow(shop);
    final pct = shop.cap > 0 ? shop.todayBookings / shop.cap : 0.0;
    final capColor = pct >= 1
        ? AppColors.redFg
        : pct >= 0.8
            ? AppColors.amberFg
            : AppColors.fgPrimary;
    final activeServices = shop.activeServices;

    return AppCard(
      onTap: onTap,
      child: Opacity(
        opacity: shop.active ? 1.0 : 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + active pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppColors.fgPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                ShopMiniPill(
                  label: shop.active ? 'Active' : 'Inactive',
                  bgColor: shop.active ? AppColors.greenBg : AppColors.greyBg,
                  fgColor: shop.active ? AppColors.greenFg : AppColors.greyFg,
                ),
              ],
            ),
            SizedBox(height: 5.h),
            // Row 2: area · open/closed · rating
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.area,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '·',
                  style: AppText.figtree(
                    size: 12.5,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  open ? 'Open' : 'Closed',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: open ? AppColors.greenFg : AppColors.fgMuted,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShopRatingStar(size: 13),
                    SizedBox(width: 4.w),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.fgPrimary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '(${shop.reviews})',
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 13.h),
            // Footer metric strip
            Container(
              padding: EdgeInsets.only(top: 13.h),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSoft),
                ),
              ),
              child: Row(
                children: [
                  _MetricCell(label: 'Today', value: '${shop.todayBookings}', color: AppColors.fgPrimary, isFirst: true),
                  _MetricCell(label: 'Capacity', value: '${shop.todayBookings}/${shop.cap}', color: capColor),
                  _MetricCell(label: 'Commission', value: shop.commissionText, color: AppColors.fgPrimary),
                  _MetricCell(label: 'Services', value: '$activeServices', color: AppColors.fgPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
    this.isFirst = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: isFirst ? 0 : 12.w),
        decoration: isFirst
            ? null
            : const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.borderSoft),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppText.figtree(
                size: 9.5,
                weight: FontWeight.w700,
                color: AppColors.fgTertiary,
                letterSpacing: 0.06,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
