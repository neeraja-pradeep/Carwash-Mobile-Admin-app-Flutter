import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/coupon.dart';

/// A single coupon list card: dashed left stub with value, code, description
/// and usage progress bar. Mirrors `CouponCard` in `screen_offers.jsx`.
class CouponCard extends StatelessWidget {
  const CouponCard({required this.coupon, required this.onTap, super.key});

  final Coupon coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = coupon.statusDisplay;
    final pct = coupon.usageFraction;
    final isActive = coupon.status == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A14141E),
              offset: Offset(0, 1.h),
              blurRadius: 2.r,
            ),
            BoxShadow(
              color: const Color(0x1A14141E),
              offset: Offset(0, 6.h),
              blurRadius: 16.r,
              spreadRadius: -6.r,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left stub — brand yellow when active, page grey otherwise
            Container(
              width: 86.w,
              color: isActive ? AppColors.brandYellow : AppColors.bgPage,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    coupon.type == 'percentage'
                        ? '${coupon.value}%'
                        : '₹${coupon.value.toInt()}',
                    style: AppText.figtree(
                      size: 20,
                      weight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'OFF',
                    style: AppText.figtree(
                      size: 9,
                      weight: FontWeight.w600,
                      color: AppColors.fgPrimary.withOpacity(0.55),
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
            ),
            // Dashed separator
            CustomPaint(
              size: Size(1.w, double.infinity),
              painter: _DashedLinePainter(),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon.code,
                            style: AppText.figtree(
                              size: 15,
                              weight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        StatusBadge(label: label, tone: tone),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      coupon.description,
                      style: AppText.figtree(
                        size: 12,
                        color: AppColors.fgTertiary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99.r),
                            child: Container(
                              height: 5.h,
                              color: AppColors.bgPage,
                              child: FractionallySizedBox(
                                widthFactor: pct,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  color: pct >= 1
                                      ? AppColors.redFg
                                      : AppColors.greenFg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${coupon.usedCount}/${coupon.usageLimit}',
                          style: AppText.figtree(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault
      ..strokeWidth = 1.5;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
