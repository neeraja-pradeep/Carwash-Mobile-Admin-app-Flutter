import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/review.dart';
import 'stars.dart';

/// A review summary card: stars + timestamp, customer · shop, 2-line excerpt.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, required this.onTap, super.key});

  final Review review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stars(rating: review.rating),
              Text(
                '${review.date}, ${review.time}',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: AppColors.fgTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  review.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(size: 14.5, weight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  '· ${review.shop}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (review.hasText)
            Text(
              '“${review.text}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(
                size: 13.5,
                weight: FontWeight.w400,
                color: AppColors.fgSecondary,
                height: 1.5,
              ),
            )
          else
            Text(
              'Rating only · no written review',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}
