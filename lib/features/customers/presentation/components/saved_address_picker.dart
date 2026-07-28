import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/features/customers/domain/entities/customer.dart';

/// Shared saved-address controls for the admin create forms (New Driver Hire /
/// Inspection and New Booking). Both screens ask the same question once a
/// customer is chosen — "which of their saved addresses is this for?" — and
/// both fall back to free text when there is nothing to pick.

/// Sentinel entry for the "type a different address" row — a saved address the
/// customer will never have, matched by identity (const canonicalisation).
const typeAddressOption = SavedAddress(label: '', text: '', isDefault: false);

/// Dropdown over a customer's saved addresses, plus an escape hatch for an
/// address that isn't in their address book.
class SavedAddressDropdown extends StatelessWidget {
  const SavedAddressDropdown({
    required this.addresses,
    required this.value,
    required this.typingAddress,
    required this.onSelected,
    required this.label,
    super.key,
  });

  final List<SavedAddress> addresses;

  /// Field label above the control — "Location" on a service request,
  /// "Address" on a booking.
  final String label;

  /// The selected saved address, or null when nothing is picked yet or the
  /// admin opted to type one instead (see [typingAddress]).
  final SavedAddress? value;
  final bool typingAddress;

  /// Fires with the chosen address, or null for "type a different address".
  final ValueChanged<SavedAddress?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value ?? (typingAddress ? typeAddressOption : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SavedAddress>(
              value: selected,
              isExpanded: true,
              itemHeight: 58.h,
              borderRadius: BorderRadius.circular(12.r),
              dropdownColor: AppColors.bgCard,
              icon: Icon(
                AppIcons.chevDown,
                size: 20.sp,
                color: AppColors.fgTertiary,
              ),
              hint: Row(
                children: [
                  Icon(AppIcons.pin, size: 16.sp, color: AppColors.fgTertiary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select saved address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.figtree(
                        size: 14.5,
                        weight: FontWeight.w400,
                        color: AppColors.fgMuted,
                      ),
                    ),
                  ),
                ],
              ),
              // Collapsed state stays one line — the menu shows the detail.
              selectedItemBuilder: (_) => [
                for (final a in addresses) _collapsedRow(a.text),
                _collapsedRow('Type a different address'),
              ],
              items: [
                for (final a in addresses)
                  DropdownMenuItem<SavedAddress>(
                    value: a,
                    child: _AddressMenuRow(address: a),
                  ),
                DropdownMenuItem<SavedAddress>(
                  value: typeAddressOption,
                  child: Row(
                    children: [
                      Icon(AppIcons.plus,
                          size: 16.sp, color: AppColors.fgSecondary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Type a different address',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.figtree(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppColors.fgSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (picked) => onSelected(
                picked == typeAddressOption ? null : picked,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _collapsedRow(String text) {
    return Row(
      children: [
        Icon(AppIcons.pin, size: 16.sp, color: AppColors.fgTertiary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.figtree(size: 14.5, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// One saved address inside the open dropdown: label + DEFAULT badge on top,
/// the full address underneath.
class _AddressMenuRow extends StatelessWidget {
  const _AddressMenuRow({required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                address.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.figtree(size: 13, weight: FontWeight.w700),
              ),
            ),
            if (address.isDefault) ...[
              SizedBox(width: 7.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  'DEFAULT',
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ],
    );
  }
}

/// Placeholder shown while a customer's saved addresses are loading.
class SavedAddressLoadingField extends StatelessWidget {
  const SavedAddressLoadingField({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 46.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.bgPage,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 15.sp,
                height: 15.sp,
                child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Loading saved addresses…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
