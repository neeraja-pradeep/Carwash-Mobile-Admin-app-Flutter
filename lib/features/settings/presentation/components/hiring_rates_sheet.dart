import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/app_settings.dart';

/// Shows the Hiring Rates bottom sheet with Driver / Inspector segments.
///
/// Mirrors `BottomSheet open={ratesSheet}` in `screen_settings.jsx`.
/// UI-only: saves are toasted but not persisted in the static prototype.
Future<void> showHiringRatesSheet(
  BuildContext context, {
  required HiringRates rates,
  required VoidCallback onSaved,
}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Hiring rates',
    footer: _RatesFooter(onSaved: onSaved),
    builder: (sheetContext) => _RatesBody(rates: rates),
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _RatesFooter extends StatelessWidget {
  const _RatesFooter({required this.onSaved});

  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton(
            label: 'Save',
            full: true,
            onPressed: () {
              Navigator.of(context).pop();
              onSaved();
            },
          ),
        ),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _RatesBody extends StatefulWidget {
  const _RatesBody({required this.rates});

  final HiringRates rates;

  @override
  State<_RatesBody> createState() => _RatesBodyState();
}

class _RatesBodyState extends State<_RatesBody> {
  String _seg = 'driver'; // 'driver' | 'inspector'

  // Driver controllers
  late final TextEditingController _firstHour;
  late final TextEditingController _hourly;
  late final TextEditingController _minHours;
  late final TextEditingController _nightSurcharge;
  late final TextEditingController _travelDay;
  late final TextEditingController _travelNight;

  // Inspector controllers
  late final TextEditingController _baseFee;
  late final TextEditingController _reportFee;
  late final TextEditingController _travelWorkday;
  late final TextEditingController _travelHoliday;

  @override
  void initState() {
    super.initState();
    final d = widget.rates.driver;
    final i = widget.rates.inspector;
    _firstHour = TextEditingController(text: '${d.firstHour}');
    _hourly = TextEditingController(text: '${d.hourly}');
    _minHours = TextEditingController(text: '${d.minHours}');
    _nightSurcharge = TextEditingController(text: '${d.nightSurcharge}');
    _travelDay = TextEditingController(text: '${d.travelDay}');
    _travelNight = TextEditingController(text: '${d.travelNight}');
    _baseFee = TextEditingController(text: '${i.baseFee}');
    _reportFee = TextEditingController(text: '${i.reportFee}');
    _travelWorkday = TextEditingController(text: '${i.travelWorkday}');
    _travelHoliday = TextEditingController(text: '${i.travelHoliday}');
  }

  @override
  void dispose() {
    for (final c in [
      _firstHour, _hourly, _minHours, _nightSurcharge, _travelDay, _travelNight,
      _baseFee, _reportFee, _travelWorkday, _travelHoliday,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Final price = these rates + distance from the customer\'s location. '
          'Customers see the computed quote in their app.',
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.45,
          ),
        ),
        SizedBox(height: 16.h),
        // Segment
        Row(
          children: [
            _SegBtn(label: 'Driver', value: 'driver', current: _seg, onTap: () => setState(() => _seg = 'driver')),
            SizedBox(width: 8.w),
            _SegBtn(label: 'Inspector', value: 'inspector', current: _seg, onTap: () => setState(() => _seg = 'inspector')),
          ],
        ),
        SizedBox(height: 18.h),
        if (_seg == 'driver') _driverFields() else _inspectorFields(),
      ],
    );
  }

  Widget _driverFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _RateField(label: 'First hour', controller: _firstHour, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Per extra hour', controller: _hourly, prefix: '₹')),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _RateField(label: 'Min hours', controller: _minHours, suffix: 'hrs')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Night surcharge', controller: _nightSurcharge, prefix: '₹')),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _RateField(label: 'Travel allowance · day', controller: _travelDay, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Travel allowance · night', controller: _travelNight, prefix: '₹')),
          ],
        ),
      ],
    );
  }

  Widget _inspectorFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _RateField(label: 'Base fee', controller: _baseFee, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Written report', controller: _reportFee, prefix: '₹')),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _RateField(label: 'Travel allowance · working day', controller: _travelWorkday, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Travel allowance · holiday', controller: _travelHoliday, prefix: '₹')),
          ],
        ),
      ],
    );
  }
}

// ── Segment button ─────────────────────────────────────────────────────────────

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.brandYellow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: on ? AppColors.brandYellowDeep : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: AppText.figtree(
              size: 13,
              weight: on ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rate input field ──────────────────────────────────────────────────────────

class _RateField extends StatelessWidget {
  const _RateField({
    required this.label,
    required this.controller,
    this.prefix,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppText.figtree(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.fgSecondary,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: Text(
                    prefix!,
                    style: AppText.figtree(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.fgSecondary,
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppText.figtree(size: 14, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: prefix != null ? 6.w : 12.w,
                      vertical: 0,
                    ),
                    isDense: true,
                    suffixText: suffix,
                    suffixStyle: AppText.figtree(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.fgSecondary,
                    ),
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

