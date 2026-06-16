import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/status/badge_tone.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/skeleton_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/customers_providers.dart';
import '../../domain/entities/customer.dart';
import '../components/block_customer_modal.dart';
import '../components/garage_tab_section.dart';
import '../components/history_tab_section.dart';
import '../components/info_tab_section.dart';

/// Customer detail screen — KPI strip, block/unblock toggle, 3 tabs
/// (Info / Garage / History), and a 3-dot menu.
///
/// [customerId] is supplied via go_router path parameter.
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  String _tab = 'info';
  bool? _blockedOverride; // null = use entity value
  String? _notesOverride; // null = use entity value
  bool _menuOpen = false;

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  void _closeMenu() => setState(() => _menuOpen = false);

  // Build a Customer reflecting local overrides (block/unblock, note edits).
  Customer _withOverrides(Customer base) {
    return Customer(
      id: base.id,
      name: base.name,
      phone: base.phone,
      email: base.email,
      joined: base.joined,
      blocked: _blockedOverride ?? base.blocked,
      blockedReason: base.blockedReason,
      notes: _notesOverride ?? base.notes,
      bookings: base.bookings,
      spend: base.spend,
      lastBooking: base.lastBooking,
      accountAge: base.accountAge,
      addresses: base.addresses,
      vehicles: base.vehicles,
      history: base.history,
    );
  }

  // ── Block action ───────────────────────────────────────────────────────────

  Future<void> _onBlock(Customer c) async {
    final reason = await showBlockCustomerModal(context);
    if (reason == null) return;
    setState(() => _blockedOverride = true);
    if (mounted) {
      AppToast.show(context, 'Customer blocked · $reason');
    }
  }

  void _onUnblock(Customer c) {
    setState(() => _blockedOverride = false);
    AppToast.show(context, 'Customer unblocked');
  }

  // ── Note edit modal ────────────────────────────────────────────────────────

  Future<void> _openNoteModal(Customer c) async {
    final ctrl = TextEditingController(text: c.notes);
    final saved = await showAppModal<String?>(
      context: context,
      builder: (dialogContext) => _NoteModalBody(
        initialNotes: c.notes,
        controller: ctrl,
        dialogContext: dialogContext,
      ),
    );
    ctrl.dispose();
    if (saved == null) return; // cancelled
    setState(() => _notesOverride = saved);
    if (mounted) {
      AppToast.show(
        context,
        saved.isNotEmpty ? 'Note saved' : 'Note cleared',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));

    return customerAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(title: 'Customer', onBack: () => context.pop()),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(16.r),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
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
          child: Column(
            children: [
              TopBar(title: 'Customer', onBack: () => context.pop()),
              Expanded(
                child: Center(
                  child: Text(
                    'Customer not found.',
                    style: AppText.figtree(
                      size: 15,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (base) {
        if (base == null) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(title: 'Customer', onBack: () => context.pop()),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Customer not found.',
                        style: AppText.figtree(
                          size: 15,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final c = _withOverrides(base);
        final isBlocked = c.blocked;

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                  children: [
                // ── Top bar ───────────────────────────────────────────────
                TopBar(
                  title: c.name,
                  onBack: () => context.pop(),
                  actions: [
                    AppIconButton(
                      icon: AppIcons.phone,
                      semanticLabel: 'Call ${c.name}',
                      iconSize: 20,
                      onTap: () =>
                          AppToast.show(context, 'Calling ${c.name}…'),
                    ),
                    AppIconButton(
                      icon: AppIcons.more,
                      semanticLabel: 'More options',
                      iconSize: 22,
                      onTap: _toggleMenu,
                    ),
                  ],
                ),

                // ── Block/Unblock controls row ────────────────────────────
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(
                        label: isBlocked ? 'Blocked' : 'Active',
                        tone: isBlocked ? BadgeTone.grey : BadgeTone.green,
                      ),
                      if (isBlocked)
                        _ActionButton(
                          label: 'Unblock',
                          onTap: () => _onUnblock(c),
                          danger: false,
                        )
                      else
                        _ActionButton(
                          label: 'Block',
                          onTap: () => _onBlock(c),
                          danger: true,
                        ),
                    ],
                  ),
                ),

                // ── KPI strip ─────────────────────────────────────────────
                _KpiStrip(customer: c),

                // ── Tab bar ───────────────────────────────────────────────
                _TabBar(
                  current: _tab,
                  onSelect: (t) => setState(() => _tab = t),
                ),

                // ── Tab body ──────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    child: _buildTab(c),
                  ),
                ),
              ],
                ),
                ),
                // ── 3-dot dropdown overlay ────────────────────────────────
                if (_menuOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeMenu,
                      behavior: HitTestBehavior.opaque,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                  Positioned(
                    top: 54.h,
                    right: 14.w,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 190.w,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MenuItem(
                              icon: AppIcons.note,
                              label: 'Add note',
                              isFirst: true,
                              onTap: () {
                                _closeMenu();
                                _openNoteModal(c);
                              },
                            ),
                            _MenuItem(
                              icon: AppIcons.copy,
                              label: 'Copy phone',
                              isFirst: false,
                              onTap: () {
                                _closeMenu();
                                AppToast.show(context, 'Phone copied');
                              },
                            ),
                            _MenuItem(
                              icon: AppIcons.share,
                              label: 'Export (CSV)',
                              isFirst: false,
                              onTap: () {
                                _closeMenu();
                                AppToast.show(context, 'Export (CSV)');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(Customer c) {
    switch (_tab) {
      case 'garage':
        return GarageTabSection(vehicles: c.vehicles);
      case 'history':
        return HistoryTabSection(
          history: c.history,
          totalBookings: c.bookings,
          onTapBooking: (h) {
            // Known booking IDs in the live dataset include DD-KL-202605* IDs
            // referenced in bookings data.jsx. Archived ones show a toast.
            final knownPrefix = RegExp(r'^DD-KL-20260529');
            if (knownPrefix.hasMatch(h.id)) {
              context.push(Routes.bookingDetail(h.id));
            } else {
              AppToast.show(
                context,
                'Archived booking — full record in Pass 1 dataset',
              );
            }
          },
        );
      default:
        return InfoTabSection(
          customer: c,
          onCallCustomer: () =>
              AppToast.show(context, 'Calling ${c.name}…'),
          onEditNotes: () => _openNoteModal(c),
        );
    }
  }
}

// ─── KPI strip ───────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final lastShort =
        customer.lastBooking.replaceFirst(RegExp(r'-2026$'), '');
    final items = <(String, String)>[
      ('Bookings', '${customer.bookings}'),
      ('Spent', Formatters.money(customer.spend)),
      ('Last', lastShort),
      ('Age', customer.accountAge),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  border: i > 0
                      ? const Border(
                          left: BorderSide(color: AppColors.borderSoft),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      items[i].$2,
                      style: AppText.figtree(
                        size: 16,
                        weight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      items[i].$1.toUpperCase(),
                      style: AppText.figtree(
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  static const List<(String, String)> _tabs = [
    ('info', 'Info'),
    ('garage', 'Garage'),
    ('history', 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(tab.$1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.fromLTRB(0, 12.h, 0, 10.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Text(
                          tab.$2,
                          style: AppText.figtree(
                            size: 14,
                            weight: current == tab.$1
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: current == tab.$1
                                ? AppColors.fgPrimary
                                : AppColors.fgTertiary,
                          ),
                        ),
                      ),
                      if (current == tab.$1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -10.h,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 22.w),
                            height: 2.5.h,
                            decoration: BoxDecoration(
                              color: AppColors.brandYellowDeep,
                              borderRadius: BorderRadius.circular(99.r),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Block / Unblock action button ───────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.danger,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: danger ? AppColors.redFg : AppColors.borderDefault,
          ),
          color: danger ? AppColors.redBg : AppColors.bgCard,
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w700,
            color: danger ? AppColors.redFg : AppColors.fgPrimary,
          ),
        ),
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isFirst,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(top: BorderSide(color: AppColors.borderSoft)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17.sp, color: AppColors.fgSecondary),
            SizedBox(width: 11.w),
            Text(
              label,
              style: AppText.figtree(size: 13.5, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note modal body (standalone StatefulWidget) ──────────────────────────────

class _NoteModalBody extends StatefulWidget {
  const _NoteModalBody({
    required this.initialNotes,
    required this.controller,
    required this.dialogContext,
  });

  final String initialNotes;
  final TextEditingController controller;
  final BuildContext dialogContext;

  @override
  State<_NoteModalBody> createState() => _NoteModalBodyState();
}

class _NoteModalBodyState extends State<_NoteModalBody> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialNotes.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEdit ? 'Edit note' : 'Add note',
          style: AppText.figtree(size: 19, weight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          'Internal note about this customer — founders only.',
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w400,
            color: AppColors.fgSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: 4,
            autofocus: true,
            style: AppText.figtree(size: 14, weight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: 'Type a note…',
              hintStyle: AppText.figtree(
                size: 14,
                weight: FontWeight.w400,
                color: AppColors.fgMuted,
              ),
              contentPadding: EdgeInsets.all(12.r),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: _ModalButton(
                label: 'Cancel',
                secondary: true,
                onTap: () => Navigator.of(widget.dialogContext).pop(null),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ModalButton(
                label: 'Save',
                onTap: () => Navigator.of(widget.dialogContext)
                    .pop(widget.controller.text.trim()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: secondary ? AppColors.bgPage : AppColors.brandYellow,
          borderRadius: BorderRadius.circular(12.r),
          border: secondary
              ? Border.all(color: AppColors.borderDefault)
              : null,
        ),
        child: Text(
          label,
          style: AppText.figtree(
            size: 15,
            weight: FontWeight.w700,
            color: secondary ? AppColors.fgPrimary : AppColors.fgOnBrand,
          ),
        ),
      ),
    );
  }
}
