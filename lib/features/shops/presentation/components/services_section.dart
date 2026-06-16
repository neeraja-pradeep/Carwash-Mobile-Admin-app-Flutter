import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/utils/formatters.dart';
import 'package:new_flutter_project/core/widgets/widgets.dart';

import '../../domain/entities/shop.dart';

/// Services tab body for ShopDetailScreen.
/// Mirrors `ServicesTab` in `screen_shopdetail.jsx`.
class ServicesSection extends StatelessWidget {
  const ServicesSection({
    required this.services,
    required this.onToggleService,
    required this.onAddService,
    required this.onEditService,
    required this.onToast,
    super.key,
  });

  final List<ShopService> services;

  /// Called with the service id to toggle its active state.
  final ValueChanged<String> onToggleService;
  final VoidCallback onAddService;
  final ValueChanged<String> onEditService;
  final void Function(String) onToast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: 'Add Service',
          full: true,
          size: AppButtonSize.sm,
          icon: AppIcons.plus,
          onPressed: onAddService,
        ),
        SizedBox(height: 14.h),
        ...services.map(
          (sv) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _ServiceRow(
              service: sv,
              onToggle: () => onToggleService(sv.id),
              onEdit: () => onEditService(sv.id),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        // Bulk options
        _BulkAction(
          icon: AppIcons.copy,
          label: 'Copy services from another shop',
          onTap: () => onToast('Copy services from another shop'),
        ),
        SizedBox(height: 10.h),
        _BulkAction(
          icon: AppIcons.rupee,
          label: 'Apply % price change to all',
          onTap: () => onToast('Apply ±% price change to all services'),
        ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.onToggle,
    required this.onEdit,
  });

  final ShopService service;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  String get _summary {
    if (service.samePrice) {
      return '${Formatters.money(service.flatPrice ?? 0)} · ${service.flatMinutes ?? 0} min · all types';
    }
    final activePricing = service.pricing.where((p) => p.active).toList();
    if (activePricing.isEmpty) return 'No vehicle types active';
    final minPrice = activePricing.map((p) => p.price).reduce(
          (a, b) => a < b ? a : b,
        );
    return '${activePricing.length} vehicle types · from ${Formatters.money(minPrice)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padded: false,
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: name + desc + summary (tappable → edit)
            Expanded(
              child: GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          service.name,
                          style: AppText.figtree(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (service.samePrice) ...[
                          SizedBox(width: 8.w),
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
                              'FLAT',
                              style: AppText.figtree(
                                size: 9.5,
                                weight: FontWeight.w600,
                                color: AppColors.blueFg,
                                letterSpacing: 0.04,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service.description,
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      _summary,
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: AppColors.fgSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Right: toggle + edit button
            Column(
              children: [
                _ServiceToggle(on: service.active, onTap: onToggle),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: onEdit,
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
                      AppIcons.edit,
                      size: 15.sp,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  const _ServiceToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: on ? AppColors.success : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
            width: 20.r,
            height: 20.r,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 2.r,
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

class _BulkAction extends StatelessWidget {
  const _BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: AppColors.fgSecondary),
            SizedBox(width: 11.w),
            Expanded(
              child: Text(
                label,
                style: AppText.figtree(
                  size: 13.5,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Icon(AppIcons.chevRight, size: 18.sp, color: AppColors.fgTertiary),
          ],
        ),
      ),
    );
  }
}
