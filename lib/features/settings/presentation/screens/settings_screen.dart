import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/settings_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../components/edit_field_sheet.dart';
import '../components/hiring_rates_sheet.dart';
import '../components/settings_group_section.dart';
import '../components/settings_item.dart';

/// Settings main screen — scrollable, single page with grouped items.
///
/// Mirrors `SettingsScreen` in `screen_settings.jsx` (lines 198–300).
/// Groups: Business · Operations · Notifications · Logout. No "About" section.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local toggle state — mirrors `notif` useState in the prototype.
  NotificationToggles? _notif;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: 'Settings',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: async.when(
                loading: () => _Skeleton(),
                error: (_, __) => const Center(
                  child: Text('Failed to load settings'),
                ),
                data: (settings) => _Body(
                  settings: settings,
                  notif: _notif ?? settings.notifications,
                  onToggle: (key) {
                    setState(() {
                      final n = _notif ?? settings.notifications;
                      _notif = _toggleKey(n, key);
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  NotificationToggles _toggleKey(NotificationToggles n, String key) {
    switch (key) {
      case 'newBooking':
        return n.copyWith(newBooking: !n.newBooking);
      case 'refundRequest':
        return n.copyWith(refundRequest: !n.refundRequest);
      case 'lowRating':
        return n.copyWith(lowRating: !n.lowRating);
      case 'dailySummary':
        return n.copyWith(dailySummary: !n.dailySummary);
      case 'payoutDue':
        return n.copyWith(payoutDue: !n.payoutDue);
      default:
        return n;
    }
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.settings,
    required this.notif,
    required this.onToggle,
  });

  final AppSettings settings;
  final NotificationToggles notif;
  final void Function(String key) onToggle;

  static const List<(String, String)> _notifItems = [
    ('newBooking', 'New booking'),
    ('refundRequest', 'Refund requests'),
    ('lowRating', 'Low ratings (≤3★)'),
    ('dailySummary', 'Daily summary'),
    ('payoutDue', 'Payout due reminders'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = settings;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      children: [
        // ── Profile header ────────────────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(AppIcons.droplet, size: 28.sp, color: AppColors.fgPrimary),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.business.name,
                      style: AppText.figtree(
                        size: 17,
                        weight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      s.business.city,
                      style: AppText.figtree(
                        size: 12.5,
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
        SizedBox(height: 18.h),

        // ── Business group ────────────────────────────────────────────────────
        SettingsGroupSection(
          label: 'Business',
          children: [
            SettingsItem(
              icon: AppIcons.store,
              title: 'Business profile',
              sub: s.business.name,
              onTap: () => showEditFieldSheet(
                context,
                title: 'Business name',
                label: 'Business name',
                initialValue: s.business.name,
                onSaved: () => AppToast.show(context, 'Business name saved'),
              ),
            ),
            SettingsItem(
              icon: AppIcons.receipt,
              title: 'GSTIN',
              sub: s.business.gstin,
              onTap: () => showEditFieldSheet(
                context,
                title: 'GSTIN',
                label: 'GSTIN',
                initialValue: s.business.gstin,
                onSaved: () => AppToast.show(context, 'GSTIN saved'),
              ),
            ),
            SettingsItem(
              icon: AppIcons.phone,
              title: 'Support contact',
              sub: '${s.business.support} · ${s.business.email}',
              last: true,
              onTap: () => showEditFieldSheet(
                context,
                title: 'Support phone',
                label: 'Support phone',
                initialValue: s.business.support,
                onSaved: () => AppToast.show(context, 'Support phone saved'),
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // ── Operations group ──────────────────────────────────────────────────
        SettingsGroupSection(
          label: 'Operations',
          children: [
            SettingsItem(
              icon: AppIcons.clock,
              title: 'Default slot interval',
              right: Text(
                '${s.slotInterval} min',
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.fgSecondary,
                ),
              ),
              onTap: () => showEditFieldSheet(
                context,
                title: 'Slot interval (min)',
                label: 'Minutes',
                initialValue: '${s.slotInterval}',
                numeric: true,
                onSaved: () => AppToast.show(context, 'Slot interval saved'),
              ),
            ),
            SettingsItem(
              icon: AppIcons.rupee,
              title: 'Default commission',
              sub: '${s.defaultCommission.pct}% of booking',
              onTap: () => showEditFieldSheet(
                context,
                title: 'Default commission %',
                label: 'Percentage',
                initialValue: '${s.defaultCommission.pct}',
                numeric: true,
                suffix: '%',
                onSaved: () => AppToast.show(context, 'Default commission % saved'),
              ),
            ),
            SettingsItem(
              icon: AppIcons.car,
              title: 'Hiring rates',
              sub: 'Driver ₹${s.rates.driver.firstHour} first hr · Inspection ₹${s.rates.inspector.baseFee}',
              onTap: () => showHiringRatesSheet(
                context,
                rates: s.rates,
                onSaved: () => AppToast.show(context, 'Hiring rates saved'),
              ),
            ),
            SettingsItem(
              icon: AppIcons.pin,
              title: 'Service areas',
              sub: '${s.serviceAreas.carwash.length + s.serviceAreas.hire.length} areas · Carwash & Hire',
              onTap: () => context.push(Routes.serviceAreas),
            ),
            SettingsItem(
              icon: AppIcons.receipt,
              title: 'Refund tiers',
              sub: 'Full / partial / none rules',
              last: true,
              onTap: () => showEditFieldSheet(
                context,
                title: 'Refund tiers',
                info:
                    'Full = before assignment · Partial (70%) = after assignment, '
                    'before pickup · None = after pickup. Editing the % rules is a '
                    'later-pass feature.',
                onSaved: () {},
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // ── Notifications group ───────────────────────────────────────────────
        SettingsGroupSection(
          label: 'Notifications',
          children: [
            for (var i = 0; i < _notifItems.length; i++)
              SettingsItem(
                icon: AppIcons.bell,
                title: _notifItems[i].$2,
                last: i == _notifItems.length - 1,
                right: Switch(
                  value: _notifValue(notif, _notifItems[i].$1),
                  onChanged: (_) => onToggle(_notifItems[i].$1),
                  activeColor: AppColors.brandYellowDeep,
                  activeTrackColor: AppColors.brandYellow,
                ),
              ),
          ],
        ),
        SizedBox(height: 18.h),

        // ── Logout ────────────────────────────────────────────────────────────
        SettingsGroupSection(
          label: '',
          children: [
            SettingsItem(
              icon: AppIcons.logout,
              title: 'Log out',
              danger: true,
              last: true,
              onTap: () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: 'Log out?',
                  body: 'You will be returned to the login screen.',
                  confirmLabel: 'Log out',
                  destructive: true,
                );
                if (confirmed && context.mounted) {
                  context.go(Routes.login);
                }
              },
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // ── Version footnote ──────────────────────────────────────────────────
        Text(
          'DriveDeck Operator Console · ${s.appVersion}',
          textAlign: TextAlign.center,
          style: AppText.figtree(
            size: 11,
            weight: FontWeight.w500,
            color: AppColors.fgMuted,
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  bool _notifValue(NotificationToggles n, String key) {
    switch (key) {
      case 'newBooking':
        return n.newBooking;
      case 'refundRequest':
        return n.refundRequest;
      case 'lowRating':
        return n.lowRating;
      case 'dailySummary':
        return n.dailySummary;
      case 'payoutDue':
        return n.payoutDue;
      default:
        return false;
    }
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        const SkeletonCard(),
        SizedBox(height: 18.h),
        const SkeletonCard(),
        SizedBox(height: 18.h),
        const SkeletonCard(),
        SizedBox(height: 18.h),
        const SkeletonCard(),
      ],
    );
  }
}
