import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../application/providers/shops_providers.dart';
import '../../domain/entities/holiday.dart';
import '../../domain/entities/shop.dart';
import 'shop_card.dart';

/// Info tab body for ShopDetailScreen.
/// Mirrors `InfoTab` in `screen_shopdetail.jsx`.
class InfoSection extends ConsumerStatefulWidget {
  const InfoSection({
    required this.shop,
    required this.active,
    required this.onActiveChanged,
    required this.onManageHours,
    super.key,
  });

  final Shop shop;
  final bool active;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onManageHours;

  @override
  ConsumerState<InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends ConsumerState<InfoSection> {
  void _toast(String msg) => AppToast.show(context, msg);

  @override
  Widget build(BuildContext context) {
    final s = widget.shop;
    final holidaysAsync = ref.watch(shopHolidaysProvider(s.id));
    final holidays = holidaysAsync.valueOrNull ?? <Holiday>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operational KPI strip
        _OpStrip(shop: s),
        SizedBox(height: 14.h),

        // Photos
        _PhotoStrip(shop: s, onToast: _toast),
        SizedBox(height: 14.h),

        // Shop identity
        _SectionCard(
          label: 'Shop Identity',
          child: Column(
            children: [
              _FieldRow(
                label: 'Owner',
                value: s.ownerName,
                action: _RowAction.call_,
                onAction: () => _toast('Calling ${s.ownerName}…'),
              ),
              _FieldRow(label: 'Owner phone', value: s.ownerPhone, mono: true),
              _FieldRow(label: 'Shop phone', value: s.shopPhone, mono: true),
              _FieldRow(label: 'Address', value: s.address, isLast: true),
              // Map preview
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () => _toast('Opening Google Maps…'),
                child: Container(
                  height: 110.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9EFE7), Color(0xFFDFE6EA)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid overlay
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      Center(
                        child: Icon(
                          AppIcons.pin,
                          size: 30.sp,
                          color: AppColors.danger,
                        ),
                      ),
                      Positioned(
                        bottom: 10.h,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8.r,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.nav, size: 14.sp),
                              SizedBox(width: 5.w),
                              Text(
                                'View location',
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Operating hours
        _SectionCard(
          label: 'Operating Hours',
          action: 'Manage',
          onAction: widget.onManageHours,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              ...List.generate(s.weekly.length, (i) {
                final h = s.weekly[i];
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  decoration: BoxDecoration(
                    border: i < 6
                        ? const Border(
                            bottom: BorderSide(color: AppColors.borderSoft),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42.w,
                        child: Text(
                          h.day,
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (h.closed)
                        Text(
                          'Off day',
                          style: AppText.figtree(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: AppColors.fgMuted,
                          ),
                        )
                      else
                        Text(
                          '${fmtHour(h.open)} – ${fmtHour(h.close)}',
                          style: AppText.figtree(
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              Container(
                margin: EdgeInsets.only(top: 12.h),
                padding: EdgeInsets.only(top: 12.h),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.droplet,
                        size: 14.sp, color: AppColors.fgTertiary),
                    SizedBox(width: 7.w),
                    Text(
                      s.slotCapacityEnabled
                          ? 'Per-slot capacity on (default ${s.slotCap}/slot)'
                          : 'Daily cap ${s.cap} · hourly slots',
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (holidays.isNotEmpty) ...[
                SizedBox(height: 9.h),
                Row(
                  children: [
                    Icon(AppIcons.calendar,
                        size: 14.sp, color: AppColors.amberFg),
                    SizedBox(width: 7.w),
                    Text(
                      'Next holiday: ${fmtHolidayDate(holidays.first.date)} · ${holidays.first.label}',
                      style: AppText.figtree(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.amberFg,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Operational config
        _SectionCard(
          label: 'Operational Config',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldRow(label: 'Daily booking cap', value: '${s.cap}'),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 11.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle types supported',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                    SizedBox(height: 9.h),
                    Wrap(
                      spacing: 7.w,
                      runSpacing: 7.h,
                      children: kVehicleTypes.map((vt) {
                        final on = s.vehicleTypes.contains(vt);
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 11.w, vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: on ? AppColors.blueBg : AppColors.bgPage,
                            borderRadius: BorderRadius.circular(999.r),
                            border: on
                                ? null
                                : Border.all(color: AppColors.borderSoft),
                          ),
                          child: Text(
                            vt,
                            style: AppText.figtree(
                              size: 12,
                              weight: FontWeight.w600,
                              color: on ? AppColors.blueFg : AppColors.fgMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Active toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop active',
                          style: AppText.figtree(
                            size: 13.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.active
                              ? 'Visible to customers'
                              : 'Hidden from customer browse',
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _AppToggle(
                    on: widget.active,
                    onChanged: (v) {
                      widget.onActiveChanged(v);
                      _toast(v ? 'Shop activated' : 'Shop marked inactive');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Commission
        _SectionCard(
          label: 'Commission',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6.h),
              Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(AppIcons.rupee, size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.commission.label,
                        style: AppText.figtree(
                          size: 18,
                          weight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _commissionDesc(s.commission.mode),
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppColors.fgTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  for (final (m, l) in [
                    (CommissionMode.percentage, 'Percentage'),
                    (CommissionMode.flat, 'Flat ₹'),
                    (CommissionMode.floor, '% + floor'),
                  ]) ...[
                    if (m != CommissionMode.percentage) SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s.commission.mode == m
                              ? AppColors.fgPrimary
                              : AppColors.bgPage,
                          borderRadius: BorderRadius.circular(9.r),
                          border: s.commission.mode != m
                              ? Border.all(color: AppColors.borderSoft)
                              : null,
                        ),
                        child: Text(
                          l,
                          style: AppText.figtree(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: s.commission.mode == m
                                ? AppColors.fgOnDark
                                : AppColors.fgTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Bank / UPI
        _SectionCard(
          label: 'Bank / UPI (payout reference)',
          child: Column(
            children: [
              _FieldRow(label: 'Account name', value: s.bank.accName),
              _FieldRow(label: 'Account no.', value: s.bank.accNo, mono: true),
              _FieldRow(label: 'IFSC', value: s.bank.ifsc, mono: true),
              _FieldRow(label: 'UPI ID', value: s.bank.upi, mono: true),
              _FieldRow(
                label: 'GSTIN',
                value: s.bank.gstin.isNotEmpty ? s.bank.gstin : '—',
                mono: true,
              ),
              _FieldRow(
                label: 'PAN', value: s.bank.pan, mono: true, isLast: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Meta
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(
            'Onboarded ${s.onboarded.date} by ${s.onboarded.by}\n'
            'Last edited ${s.lastEdited.date} by ${s.lastEdited.by}',
            textAlign: TextAlign.center,
            style: AppText.figtree(
              size: 11.5,
              weight: FontWeight.w500,
              color: AppColors.fgMuted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  String _commissionDesc(CommissionMode mode) => switch (mode) {
        CommissionMode.percentage => 'Percentage of each booking',
        CommissionMode.flat => 'Flat fee per booking',
        CommissionMode.floor => 'Percentage with minimum floor',
      };
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _OpStrip extends StatelessWidget {
  const _OpStrip({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final open = shopIsOpenNow(shop);
    final items = [
      ('Today', '${shop.todayBookings}', AppColors.fgPrimary),
      ('Cap used', '${shop.todayBookings}/${shop.cap}', AppColors.fgPrimary),
      ('Avg time', '${shop.avgServiceMin}m', AppColors.fgPrimary),
      (
        'Status',
        open ? 'Open' : 'Closed',
        open ? AppColors.greenFg : AppColors.fgTertiary,
      ),
    ];

    return AppCard(
      padded: false,
      child: Row(
        children: List.generate(items.length, (i) {
          final it = items[i];
          return Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
              decoration: i > 0
                  ? const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.borderSoft),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    it.$2,
                    style: AppText.figtree(
                      size: 18,
                      weight: FontWeight.w800,
                      color: it.$3,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    it.$1.toUpperCase(),
                    style: AppText.figtree(
                      size: 10,
                      weight: FontWeight.w600,
                      color: AppColors.fgTertiary,
                      letterSpacing: 0.06,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.shop, required this.onToast});
  final Shop shop;
  final void Function(String) onToast;

  @override
  Widget build(BuildContext context) {
    final photos = shop.photos.take(3).toList();
    final cells = <Widget>[];

    for (int i = 0; i < 3; i++) {
      if (i < photos.length) {
        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: () => onToast('Open photo full-screen'),
              child: Container(
                height: 92.h,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(12.r),
                  image: DecorationImage(
                    image: AssetImage(photos[i]),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: i == 0
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: EdgeInsets.all(7.r),
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'COVER',
                            style: AppText.figtree(
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 0.06,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      } else {
        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: () => onToast('Upload photo (camera / gallery)'),
              child: Container(
                height: 92.h,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.borderDefault,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.plus, size: 20.sp, color: AppColors.fgTertiary),
                    SizedBox(height: 4.h),
                    Text(
                      'Add',
                      style: AppText.figtree(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (i < 2) cells.add(SizedBox(width: 10.w));
    }

    return Row(children: cells);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.child,
    this.action,
    this.onAction,
  });

  final String label;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.fgSecondary,
                  letterSpacing: 0.1,
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          child,
        ],
      ),
    );
  }
}

enum _RowAction { call_, navigate }

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.action,
    this.onAction,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool mono;
  final _RowAction? action;
  final VoidCallback? onAction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
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
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: mono
                  ? TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fgPrimary,
                    )
                  : AppText.figtree(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.fgPrimary,
                    ),
            ),
          ),
          if (action != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onAction,
              child: Container(
                width: 32.r,
                height: 32.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Icon(
                  action == _RowAction.call_ ? AppIcons.phone : AppIcons.nav,
                  size: 16.sp,
                  color: AppColors.fgSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple toggle switch.
class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: on ? AppColors.success : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: 22.r,
            height: 22.r,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid painter for the map preview background.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
