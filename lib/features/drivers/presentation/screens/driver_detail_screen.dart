import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/router/app_router.dart';
import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_card.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icon_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/avatar.dart';
import 'package:new_flutter_project/core/widgets/skeleton_card.dart';
import 'package:new_flutter_project/core/widgets/status_badge.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';

import '../../application/providers/drivers_providers.dart';
import '../../domain/entities/field_driver.dart';
import '../../infrastructure/models/driver_response_model.dart';
import '../components/documents_section.dart';
import '../components/live_job_card.dart';
import 'hire_driver_screen.dart';

/// Full driver profile screen — pushed from DriversScreen via [Routes.driverDetail].
///
/// Layout (top to bottom):
/// 1. TopBar with back, phone icon, 3-dot menu (Edit/Resend invite/Suspend)
/// 2. Hero card (avatar, name, status, rating)
/// 3. Live "On a job" card [if driver.onJob]
/// 4. Role assignment card (segmented chips, read-only display)
/// 5. Profile card (phone, email, license no/expiry/verified, joined)
/// 6. Documents section (view/add/edit/delete)
/// 7. Performance strip (jobs done, week jobs, week earnings)
/// 8. Invited banner (if invited)
class DriverDetailScreen extends ConsumerStatefulWidget {
  const DriverDetailScreen({required this.driverId, super.key});

  final String driverId;

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final driverAsync = ref.watch(fieldDriverByIdProvider(widget.driverId));

    return driverAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                title: 'Driver',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (_, __) => const SkeletonCard(),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                title: 'Driver',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Driver not found',
                    style: AppText.figtree(
                      size: 15,
                      weight: FontWeight.w500,
                      color: AppColors.fgTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (driver) {
        if (driver == null) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  TopBar(
                    title: 'Driver',
                    onBack: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('Driver not found')),
                  ),
                ],
              ),
            ),
          );
        }

        final status = driver.status;
        final docs = driver.documents;
        final onJob = driver.onJob && status == DriverStatus.online;

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    TopBar(
                      title: 'Driver',
                      onBack: () => context.pop(),
                      actions: [
                        AppIconButton(
                          icon: AppIcons.phone,
                          semanticLabel: 'Call ${driver.name}',
                          onTap: () =>
                              AppToast.show(context, 'Calling ${driver.name}…'),
                        ),
                        AppIconButton(
                          icon: AppIcons.more,
                          semanticLabel: 'More options',
                          onTap: () => setState(() => _menuOpen = !_menuOpen),
                        ),
                      ],
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(
                            fieldDriverByIdProvider(widget.driverId),
                          );
                          await ref.read(
                            fieldDriverByIdProvider(widget.driverId).future,
                          );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16.w,
                            16.h,
                            16.w,
                            24.h,
                          ),
                          children: [
                            // ── Hero card ──────────────────────────────────
                            _HeroCard(driver: driver, status: status),
                            SizedBox(height: 14.h),

                            // ── Live job card (only when on a job) ─────────
                            if (onJob && driver.currentJob != null) ...[
                              LiveJobCard(
                                job: driver.currentJob!,
                                onOpenBooking: () => context.push(
                                  Routes.bookingDetail(
                                    driver.currentJob!.bookingId,
                                  ),
                                ),
                                onReassign: () => AppToast.show(
                                  context,
                                  'Reassign from booking detail',
                                ),
                              ),
                              SizedBox(height: 14.h),
                            ],

                            // ── Role assignment ────────────────────────────
                            _RoleCard(driver: driver),
                            SizedBox(height: 14.h),

                            // ── Profile / contact + license ────────────────
                            _ProfileCard(driver: driver),
                            SizedBox(height: 14.h),

                            // ── Documents (real uploads / verify / delete) ─
                            DocumentsSection(
                              documents: docs,
                              workerId: driver.id,
                              onChanged: (_) {},
                            ),
                            SizedBox(height: 14.h),

                            // ── Performance strip ──────────────────────────
                            _PerfStrip(driver: driver),
                            SizedBox(height: 14.h),

                            // ── Invited banner ─────────────────────────────
                            if (status == DriverStatus.invited)
                              _InvitedBanner(name: driver.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 3-dot dropdown menu
                if (_menuOpen)
                  _DropdownMenu(
                    status: status,
                    driver: driver,
                    onDismiss: () => setState(() => _menuOpen = false),
                    onEditProfile: () {
                      setState(() => _menuOpen = false);
                      // Full-screen edit form, prefilled from this driver.
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HireDriverScreen(driver: driver),
                        ),
                      );
                    },
                    onResendInvite: () {
                      // Inert — no SMS/invite workflow exists (🟡 gap).
                      setState(() => _menuOpen = false);
                      AppToast.show(
                        context,
                        'Invites are not enabled yet',
                      );
                    },
                    onToggleSuspend: () async {
                      setState(() => _menuOpen = false);
                      final isSuspended = status == DriverStatus.suspended;
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: isSuspended
                            ? 'Reactivate this driver?'
                            : 'Suspend this driver?',
                        body: isSuspended
                            ? "They'll be able to receive jobs and sign in again."
                            : "They'll be removed from assignment and can't sign in until reactivated.",
                        confirmLabel: isSuspended ? 'Reactivate' : 'Suspend',
                        destructive: !isSuspended,
                      );
                      if (!confirmed || !context.mounted) return;
                      try {
                        await ref.read(driverMutationsProvider).updateDriver(
                              driver.id,
                              status: isSuspended ? 'active' : 'suspended',
                            );
                        if (!context.mounted) return;
                        AppToast.show(
                          context,
                          isSuspended
                              ? 'Driver reactivated'
                              : 'Driver suspended',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        AppToast.show(
                          context,
                          e.toString().replaceFirst('Exception: ', ''),
                        );
                      }
                    },
                    onDelete: () async {
                      setState(() => _menuOpen = false);
                      final confirmed = await showConfirmDialog(
                        context: context,
                        title: 'Remove this driver?',
                        body:
                            "This deletes the driver and their account. This can't be undone.",
                        confirmLabel: 'Remove',
                        destructive: true,
                      );
                      if (!confirmed || !context.mounted) return;
                      try {
                        await ref
                            .read(driverMutationsProvider)
                            .deleteDriver(driver.id);
                        if (!context.mounted) return;
                        AppToast.show(context, 'Driver removed');
                        context.pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        AppToast.show(
                          context,
                          e.toString().replaceFirst('Exception: ', ''),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.driver, required this.status});

  final FieldDriver driver;
  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(18.r),
      child: Row(
        children: [
          Avatar(name: driver.name, size: 56),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: AppText.figtree(
                    size: 18,
                    weight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    StatusBadge(
                      label: status.label,
                      tone: status.tone,
                    ),
                    if (driver.rating != null) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        AppIcons.star,
                        size: 13.sp,
                        color: AppColors.brandYellowWarm,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        driver.rating!.toString(),
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
    );
  }
}

// ── Role assignment card ──────────────────────────────────────────────────────

class _RoleCard extends ConsumerStatefulWidget {
  const _RoleCard({required this.driver});

  final FieldDriver driver;

  @override
  ConsumerState<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends ConsumerState<_RoleCard> {
  late String _role;
  bool _saving = false;

  /// Role labels offered for drivers (excludes the "Inspector" pseudo-role —
  /// converting driver↔inspector is out of scope, 🟡 gap).
  List<String> get _roleOptions =>
      kDriverRoles.where((r) => r != 'Inspector').toList();

  @override
  void initState() {
    super.initState();
    _role = roleLabelFromSubRole(widget.driver.subRole);
  }

  Future<void> _setRole(String label) async {
    if (_saving || label == _role) return;
    final previous = _role;
    setState(() {
      _role = label;
      _saving = true;
    });
    try {
      await ref.read(driverMutationsProvider).updateDriver(
            widget.driver.id,
            subRole: subRoleFromLabel(label),
          );
      if (mounted) AppToast.show(context, 'Role set: $label');
    } catch (e) {
      if (mounted) {
        setState(() => _role = previous);
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSIGNED ROLE',
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12.h),
          // Role segmented chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final r in _roleOptions)
                AppChip(
                  label: r
                      .replaceAll(' driver', '')
                      .replaceAll('Wash + hire', 'Wash+Hire'),
                  active: _role == r,
                  onTap: () => _setRole(r),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Controls which job types this driver can be assigned — carwash, driver hire, or inspection.',
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile / contact + license card ─────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.driver});

  final FieldDriver driver;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE',
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 4.h),
          _ProfileRow(label: 'Phone', value: driver.phone, mono: true),
          _ProfileRow(
            label: 'Email',
            value: driver.email.isEmpty ? '—' : driver.email,
          ),
          _ProfileRow(
            label: 'License no.',
            value: driver.license.number,
            mono: true,
          ),
          _ProfileRow(
            label: 'License expiry',
            value: driver.license.expiry,
          ),
          _ProfileRow(
            label: 'Verification',
            value: driver.license.verified ? 'Verified' : 'Pending',
            verified: driver.license.verified,
          ),
          // Joined (last row, no border)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 11.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Joined',
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.fgTertiary,
                  ),
                ),
                Text(
                  driver.joined,
                  style: AppText.figtree(
                    size: 13.5,
                    weight: FontWeight.w600,
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.verified,
  });

  final String label;
  final String value;
  final bool mono;
  final bool? verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verified != null) ...[
                  Icon(
                    verified! ? AppIcons.checkCircle : AppIcons.clock,
                    size: 14.sp,
                    color: verified! ? AppColors.greenFg : AppColors.amberFg,
                  ),
                  SizedBox(width: 5.w),
                ],
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: mono
                        ? AppText.figtree(
                            size: 13,
                            weight: FontWeight.w600,
                          )
                        : AppText.figtree(
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

// ── Performance strip ─────────────────────────────────────────────────────────

class _PerfStrip extends StatelessWidget {
  const _PerfStrip({required this.driver});

  final FieldDriver driver;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Jobs done', driver.jobsDone.toString()),
      ('This week', '${driver.week.jobs} jobs'),
      ('Week earnings', Formatters.money(driver.week.earnings)),
    ];

    return AppCard(
      padded: false,
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 56.h,
                color: AppColors.borderSoft,
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 8.w),
                child: Column(
                  children: [
                    Text(
                      metrics[i].$2,
                      style: AppText.figtree(
                        size: 16,
                        weight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      metrics[i].$1.toUpperCase(),
                      style: AppText.figtree(
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Invited banner ────────────────────────────────────────────────────────────

class _InvitedBanner extends StatelessWidget {
  const _InvitedBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(AppIcons.message, size: 18.sp, color: AppColors.amberFg),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Invite sent. $name can sign in to the Driver app with their number once they accept.',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.amberFg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3-dot dropdown menu ───────────────────────────────────────────────────────

class _DropdownMenu extends StatelessWidget {
  const _DropdownMenu({
    required this.status,
    required this.driver,
    required this.onDismiss,
    required this.onEditProfile,
    required this.onResendInvite,
    required this.onToggleSuspend,
    required this.onDelete,
  });

  final DriverStatus status;
  final FieldDriver driver;
  final VoidCallback onDismiss;
  final VoidCallback onEditProfile;
  final VoidCallback onResendInvite;
  final VoidCallback onToggleSuspend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == DriverStatus.suspended;
    final items = <(String, IconData, bool, VoidCallback)>[
      (
        'Edit profile',
        AppIcons.edit,
        false,
        onEditProfile,
      ),
      (
        'Resend invite',
        AppIcons.message,
        false,
        onResendInvite,
      ),
      (
        isSuspended ? 'Reactivate' : 'Suspend',
        isSuspended ? AppIcons.checkCircle : AppIcons.power,
        !isSuspended,
        onToggleSuspend,
      ),
      (
        'Remove driver',
        AppIcons.trash,
        true,
        onDelete,
      ),
    ];

    return Stack(
      children: [
        // Dismiss scrim
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Menu card
        Positioned(
          top: 54.h, // below the TopBar
          right: 14.w,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200.w,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    offset: Offset(0, 10.h),
                    blurRadius: 30.r,
                    spreadRadius: -6.r,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _MenuItem(
                        label: items[i].$1,
                        icon: items[i].$2,
                        destructive: items[i].$3,
                        showTopBorder: i > 0,
                        onTap: items[i].$4,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.destructive,
    required this.showTopBorder,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool destructive;
  final bool showTopBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.redFg : AppColors.fgPrimary;
    final iconColor = destructive ? AppColors.redFg : AppColors.fgSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          border: showTopBorder
              ? const Border(
                  top: BorderSide(color: AppColors.borderSoft),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17.sp, color: iconColor),
            SizedBox(width: 11.w),
            Text(
              label,
              style: AppText.figtree(
                size: 13.5,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
