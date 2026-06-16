import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../drivers/domain/entities/field_driver.dart';
import '../../application/providers/driver_app_providers.dart';

/// Driver app "Profile" tab — driver name, rating, info rows, sign out.
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(signedInDriverProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border:
                    Border(bottom: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style:
                          AppText.figtree(size: 18, weight: FontWeight.w700),
                    ),
                  ),
                  Icon(AppIcons.users,
                      size: 22.sp, color: AppColors.fgTertiary),
                ],
              ),
            ),

            Expanded(
              child: driverAsync.when(
                loading: () => ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 2,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
                error: (_, __) => const Center(
                  child: Text('Could not load profile.'),
                ),
                data: (driver) => _ProfileBody(
                  driver: driver,
                  onSignOut: () => context.go(Routes.login),
                ),
              ),
            ),
          ],
        ),
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

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        // Avatar card
        AppCard(
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
                      style: AppText.figtree(
                        size: 17,
                        weight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      d.role,
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Active badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: d.status == DriverStatus.active
                            ? AppColors.greenBg
                            : AppColors.amberBg,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              color: d.status == DriverStatus.active
                                  ? AppColors.greenFg
                                  : AppColors.amberFg,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            d.status.label,
                            style: AppText.figtree(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: d.status == DriverStatus.active
                                  ? AppColors.greenFg
                                  : AppColors.amberFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (d.rating != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.star,
                        size: 20.sp, color: AppColors.brandYellow),
                    SizedBox(height: 2.h),
                    Text(
                      d.rating!.toStringAsFixed(1),
                      style: AppText.figtree(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Info rows
        AppCard(
          padded: false,
          child: Column(
            children: [
              _InfoRow(
                icon: AppIcons.phone,
                label: 'Phone',
                value: d.phone,
              ),
              _Divider(),
              _InfoRow(
                icon: AppIcons.mail,
                label: 'Email',
                value: d.email.isEmpty ? '—' : d.email,
              ),
              _Divider(),
              _InfoRow(
                icon: AppIcons.doc,
                label: 'License',
                value: d.license.number,
              ),
              _Divider(),
              _InfoRow(
                icon: AppIcons.shield,
                label: 'Role',
                value: d.role,
              ),
              _Divider(),
              _InfoRow(
                icon: AppIcons.check,
                label: 'Jobs Done',
                value: '${d.jobsDone}',
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Vehicle classes
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Classes',
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.fgTertiary,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: d.vehicleClasses
                    .map(
                      (vc) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(8.r),
                          border:
                              Border.all(color: AppColors.borderDefault),
                        ),
                        child: Text(
                          vc,
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Stats
        AppCard(
          child: Row(
            children: [
              _StatBox(
                label: 'Today',
                jobs: d.today.jobs,
                earnings: d.today.earnings,
              ),
              Container(
                width: 1,
                height: 40.h,
                color: AppColors.borderSoft,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              _StatBox(
                label: 'This Week',
                jobs: d.week.jobs,
                earnings: d.week.earnings,
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Menu rows
        AppCard(
          padded: false,
          child: Column(
            children: [
              _MenuRow(
                icon: AppIcons.message,
                label: 'Help & Support',
                onTap: () {},
              ),
              _Divider(),
              _MenuRow(
                icon: AppIcons.doc,
                label: 'Terms & Conditions',
                onTap: () {},
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Sign out
        AppButton(
          label: 'Sign Out',
          kind: AppButtonKind.danger,
          icon: AppIcons.logout,
          full: true,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.fgTertiary),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w400,
                color: AppColors.fgTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: AppText.figtree(
              size: 13.5,
              weight: FontWeight.w600,
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: AppColors.fgTertiary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style:
                    AppText.figtree(size: 14, weight: FontWeight.w500),
              ),
            ),
            Icon(AppIcons.chevRight,
                size: 18.sp, color: AppColors.fgMuted),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.borderFaint);
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.jobs,
    required this.earnings,
  });

  final String label;
  final int jobs;
  final int earnings;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.fgTertiary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            Formatters.money(earnings),
            style: AppText.figtree(size: 16, weight: FontWeight.w700),
          ),
          Text(
            Formatters.count(jobs, 'job'),
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w400,
              color: AppColors.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
