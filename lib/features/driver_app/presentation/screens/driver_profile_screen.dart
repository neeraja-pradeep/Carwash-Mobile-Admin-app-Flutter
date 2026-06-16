import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../drivers/domain/entities/field_driver.dart';
import '../../application/providers/driver_app_providers.dart';

/// Driver app "Profile" tab — profile header (name, status, rating), an info
/// card, support/legal links and Sign out. Mirrors the `profile` branch of
/// `DriverApp` in `screen_driver_app.jsx`, which has no per-tab title bar — the
/// shared driver header (rendered by [DriverShell]) sits above this content.
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(signedInDriverProvider);

    return driverAsync.when(
      loading: () => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: 2,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const SkeletonCard(),
      ),
      error: (_, __) => const Center(child: Text('Could not load profile.')),
      data: (driver) => _ProfileBody(
        driver: driver,
        onSignOut: () => context.go(Routes.login),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.driver, required this.onSignOut});

  final FieldDriver? driver;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final d = driver;
    if (d == null) {
      return const Center(child: Text('Driver not found.'));
    }

    final rows = <(String, String)>[
      ('Phone', d.phone),
      ('Email', d.email.isEmpty ? '—' : d.email),
      ('License', d.license.number),
      ('Role', d.role),
      ('Jobs done', '${d.jobsDone}'),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        // Profile header card
        AppCard(
          padding: EdgeInsets.all(18.r),
          child: Row(
            children: [
              Avatar(name: d.name, size: 56),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: AppText.figtree(size: 18, weight: FontWeight.w700),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        StatusBadge(label: d.status.label, tone: d.status.tone),
                        if (d.rating != null) ...[
                          SizedBox(width: 8.w),
                          Icon(AppIcons.star,
                              size: 13.sp, color: AppColors.brandWarning),
                          SizedBox(width: 4.w),
                          Text(
                            d.rating!.toStringAsFixed(1),
                            style: AppText.figtree(
                              size: 12.5,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Info card (plain label/value rows)
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _InfoRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Support / legal links
        AppCard(
          padded: false,
          child: Column(
            children: [
              _MenuRow(
                icon: AppIcons.message,
                label: 'Help & support',
                showDivider: true,
                onTap: () => AppToast.show(context, 'Help & support'),
              ),
              _MenuRow(
                icon: AppIcons.note,
                label: 'Terms & privacy',
                showDivider: false,
                onTap: () => AppToast.show(context, 'Terms & privacy'),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Sign out — bordered white button with red label + logout icon
        GestureDetector(
          onTap: onSignOut,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 50.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.logout, size: 18.sp, color: AppColors.redFg),
                SizedBox(width: 8.w),
                Text(
                  'Sign out',
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.redFg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
            : null,
      ),
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figtree(size: 13.5, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.showDivider,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.borderSoft))
              : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: AppColors.fgSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: AppText.figtree(size: 13.5, weight: FontWeight.w600),
              ),
            ),
            Icon(AppIcons.chevRight, size: 17.sp, color: AppColors.fgMuted),
          ],
        ),
      ),
    );
  }
}
