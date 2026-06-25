import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_chip.dart';

/// A labelled card section used in offer forms.
class OfferFCard extends StatelessWidget {
  const OfferFCard({
    required this.label,
    required this.children,
    super.key,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }
}

/// A text-field row with label, optional prefix/suffix and placeholder.
class OfferFInput extends StatelessWidget {
  const OfferFInput({
    required this.label,
    required this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.optional = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final TextInputType? keyboardType;
  final bool optional;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            if (optional) ...[
              SizedBox(width: 4.w),
              Text(
                '(optional)',
                style: AppText.figtree(
                  size: 11,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              if (prefix != null && prefix!.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Text(
                  prefix!,
                  style: AppText.figtree(
                    size: 14,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 4.w),
              ] else
                SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.figtree(
                      size: 14, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: AppText.figtree(
                      size: 14,
                      color: AppColors.fgMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffix != null && suffix!.isNotEmpty) ...[
                Text(
                  suffix!,
                  style: AppText.figtree(
                    size: 14,
                    color: AppColors.fgTertiary,
                  ),
                ),
                SizedBox(width: 12.w),
              ] else
                SizedBox(width: 12.w),
            ],
          ),
        ),
      ],
    );
  }
}

/// A segmented 2-tab control with animated pill.
class OfferSegControl extends StatelessWidget {
  const OfferSegControl({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.all(3.r),
      child: Row(
        children: options.map((opt) {
          final active = value == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      active ? AppColors.bgCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            blurRadius: 4.r,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  opt.$2,
                  style: AppText.figtree(
                    size: 13.5,
                    weight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: active
                        ? AppColors.fgPrimary
                        : AppColors.fgTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// An animated toggle switch (yellow when on).
class OfferToggle extends StatelessWidget {
  const OfferToggle({required this.on, required this.onTap, super.key});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: on ? AppColors.brandYellow : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(3.r),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment:
                on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x33000000),
                    blurRadius: 4.r,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chips for selecting specific shops (by shop id, matching the API
/// `shop_ids` write field).
class ShopScopeChips extends StatelessWidget {
  const ShopScopeChips({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  /// Demo shop set mapped to ids (id → label). Real ids come from the
  /// shops API; this preserves the existing offline demo labels.
  static const Map<int, String> allShops = {
    1: 'SparkleWash Mullackal',
    2: 'AquaShine Thathampally',
    3: 'GleamPro Vazhicherry',
    4: 'BlueWave Komala Rd',
    5: 'ShineHub Iron Bridge',
  };

  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: allShops.entries.map((e) {
        final active = selected.contains(e.key);
        return AppChip(
          label: e.value.split(' ').first,
          active: active,
          onTap: () => onToggle(e.key),
        );
      }).toList(),
    );
  }
}
