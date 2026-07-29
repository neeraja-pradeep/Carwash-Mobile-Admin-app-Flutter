import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/offer_banner.dart';

/// A single banner list card: image hero with gradient overlay, status pill
/// and placement badge, plus impressions/taps footer row.
/// Mirrors `BannerCard` in `screen_offers.jsx`.
class BannerCard extends StatelessWidget {
  const BannerCard({
    required this.banner,
    required this.onTap,
    super.key,
  });

  final OfferBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = banner.statusDisplay;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with gradient overlay
            SizedBox(
              height: 116.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // CDN artwork, or a flat placeholder when the banner has none.
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fgSecondary.withValues(alpha: 0.25),
                      image: banner.hasImage
                          ? DecorationImage(
                              image: NetworkImage(banner.imageUrl!),
                              fit: BoxFit.cover,
                              // A dead CDN link must not take the list down —
                              // the placeholder colour shows through instead.
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                  ),
                  // Dark gradient at bottom for text legibility
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x0D000000),
                          Color(0xC7000000),
                        ],
                      ),
                    ),
                  ),
                  // Status badge — top left
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: StatusBadge(label: label, tone: tone),
                  ),
                  // Placement + order badge — top right
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0x73000000),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '#${banner.displayOrder} · ${banner.placementLabel}',
                        style: AppText.figtree(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.fgOnDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  // Title + subtitle — bottom left
                  Positioned(
                    left: 12.w,
                    right: 12.w,
                    bottom: 10.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: AppText.figtree(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.fgOnDark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          banner.subtitle,
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.fgOnDark.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer row: link + impressions/taps
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              child: Row(
                children: [
                  Icon(
                    AppIcons.tag,
                    size: 14.sp,
                    color: AppColors.fgSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      banner.linkLabel,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_fmt(banner.impressionCount)} views · ${banner.tapCount} taps',
                    style: AppText.figtree(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
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

  String _fmt(int n) {
    if (n >= 1000) {
      final s = n.toString();
      // Indian grouping: last 3, then pairs
      if (s.length <= 3) return s;
      if (s.length <= 5) {
        return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
      }
      return '${s.substring(0, s.length - 5)},${s.substring(s.length - 5, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '$n';
  }
}
