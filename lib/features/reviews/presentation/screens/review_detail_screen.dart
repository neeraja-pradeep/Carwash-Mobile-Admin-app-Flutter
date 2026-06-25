import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/reviews_providers.dart';
import '../../domain/entities/review.dart';
import '../components/stars.dart';

/// Read-only review detail (pushed from the Reviews list). No moderation in v0.1.
/// Fetches the full record from the detail endpoint, using the list summary as
/// an instant fallback while it loads.
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({required this.review, super.key});

  /// The list-card summary used to render immediately (detail enriches it).
  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reviewDetailProvider(review.id));
    final r = detail.valueOrNull ?? review;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Review',
              onBack: () => Navigator.of(context).pop(),
              actions: [
                AppIconButton(
                  icon: AppIcons.share,
                  iconSize: 20,
                  semanticLabel: 'Share',
                  onTap: () => AppToast.show(context, 'Share review'),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  _ScoreCard(review: r),
                  SizedBox(height: 14.h),
                  if (r.isFlagged) ...[
                    const _FlaggedBanner(),
                    SizedBox(height: 14.h),
                  ],
                  _BodyCard(review: r),
                  if (r.tags.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _TagsCard(tags: r.tags),
                  ],
                  SizedBox(height: 14.h),
                  _MetaCard(review: r),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      'View only · no moderation in v0.1. Handle offensive or fake '
                      'reviews out-of-band.',
                      textAlign: TextAlign.center,
                      style: AppText.figtree(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: AppColors.fgMuted,
                        height: 1.5,
                      ),
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        children: [
          Stars(rating: review.rating, size: 26),
          SizedBox(height: 12.h),
          Text(
            review.rating.toDouble().toStringAsFixed(1),
            style: AppText.figtree(
              size: 30,
              weight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Posted ${review.date}, ${review.time}',
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(18.r),
      child: review.hasText
          ? Text(
              '“${review.text}”',
              style: AppText.figtree(size: 16, weight: FontWeight.w400, height: 1.6),
            )
          : Text(
              'Rating only — no written review.',
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w500,
                color: AppColors.fgMuted,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, IconData)>[
      ('Shop', review.shop, AppIcons.store),
      ('Booking', review.bookingId.replaceFirst('DD-KL-2026', '#…'), AppIcons.cal),
      ('Handled by', review.drivers.join(', '), AppIcons.car),
    ];
    return AppCard(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 11.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUSTOMER', style: AppText.eyebrow),
                    SizedBox(height: 5.h),
                    Text(
                      review.customer,
                      style:
                          AppText.figtree(size: 14.5, weight: FontWeight.w700),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () =>
                      AppToast.show(context, 'Calling ${review.customer}…'),
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Icon(AppIcons.phone,
                        size: 17.sp, color: AppColors.fgSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.borderSoft))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(rows[i].$3, size: 17.sp, color: AppColors.fgTertiary),
                  SizedBox(width: 11.w),
                  SizedBox(
                    width: 76.w,
                    child: Text(
                      rows[i].$1,
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.figtree(
                        size: 13.5,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tag chips (detail-only) — free-form tokens like "Quick", "Friendly".
class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TAGS', style: AppText.eyebrow),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 9.w,
            runSpacing: 9.h,
            children: [for (final tag in tags) AppChip(label: tag)],
          ),
        ],
      ),
    );
  }
}

/// Informational flag banner (no moderation action in v0.1).
class _FlaggedBanner extends StatelessWidget {
  const _FlaggedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.redDot),
      ),
      child: Row(
        children: [
          Icon(AppIcons.alert, size: 18.sp, color: AppColors.redFg),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Flagged for review (informational only).',
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.redFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
