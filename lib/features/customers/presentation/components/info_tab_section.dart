import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/customer.dart';

/// Info tab content for the Customer Detail screen.
///
/// Shows contact details, a block-reason alert when blocked, saved addresses
/// (read-only), and founder notes (with an Edit / Add inline action).
class InfoTabSection extends StatelessWidget {
  const InfoTabSection({
    required this.customer,
    required this.onCallCustomer,
    required this.onEditNotes,
    super.key,
  });

  final Customer customer;
  final VoidCallback onCallCustomer;
  final VoidCallback onEditNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Contact card ─────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(text: 'Contact'),
              _InfoRow(label: 'Name', value: customer.name),
              _InfoRow(
                label: 'Phone',
                value: customer.phone,
                mono: true,
                action: true,
                onAction: onCallCustomer,
              ),
              _InfoRow(
                label: 'Email',
                value: customer.email.isNotEmpty ? customer.email : '—',
              ),
              _InfoRow(label: 'Joined', value: customer.joined, last: true),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // ── Block alert ───────────────────────────────────────────────────────
        if (customer.blocked) ...[
          Container(
            padding: EdgeInsets.all(13.r),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.alert, size: 18.sp, color: AppColors.redFg),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocked · ${customer.blockedReason}',
                        style: AppText.figtree(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.redFg,
                        ),
                      ),
                      if (customer.notes.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          customer.notes,
                          style: AppText.figtree(
                            size: 12,
                            weight: FontWeight.w400,
                            color: AppColors.redFg,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // ── Saved addresses card ──────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(text: 'Saved Addresses'),
              SizedBox(height: 4.h),
              for (final a in customer.addresses) ...[
                SizedBox(height: 10.h),
                _AddressRow(address: a),
              ],
              SizedBox(height: 10.h),
              Text(
                'Read-only · managed by customer',
                style: AppText.figtree(
                  size: 11,
                  weight: FontWeight.w500,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // ── Founder notes card ────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(
                text: 'Founder Notes',
                action: customer.notes.isNotEmpty ? 'Edit' : 'Add',
                onAction: onEditNotes,
              ),
              SizedBox(height: 4.h),
              Text(
                customer.notes.isNotEmpty ? customer.notes : 'No notes yet.',
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w400,
                  color: customer.notes.isNotEmpty
                      ? AppColors.fgSecondary
                      : AppColors.fgMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Internal helpers ──────────────────────────────────────────────────────────

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1.0,
            ),
          ),
          if (action != null && onAction != null)
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.last = false,
    this.action = false,
    this.onAction,
  });

  final String label;
  final String value;
  final bool mono;
  final bool last;
  final bool action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderSoft)),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 200.w),
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
                        ),
                ),
              ),
              if (action) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDefault),
                      borderRadius: BorderRadius.circular(9.r),
                      color: AppColors.bgCard,
                    ),
                    child: Icon(
                      AppIcons.phone,
                      size: 16.sp,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1.h),
          child: Icon(
            AppIcons.pin,
            size: 16.sp,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    address.label,
                    style: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (address.isDefault) ...[
                    SizedBox(width: 7.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueBg,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        'Default'.toUpperCase(),
                        style: AppText.figtree(
                          size: 9,
                          weight: FontWeight.w600,
                          color: AppColors.blueFg,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                address.text,
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w400,
                  color: AppColors.fgSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
