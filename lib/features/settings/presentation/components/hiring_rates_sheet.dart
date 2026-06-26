import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/typography.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/app_settings.dart';

/// Values collected by the hiring-rates sheet — only the screen-editable subset
/// that maps to backend fields (see §13.2). Travel allowance maps to the
/// driver's tiered "base per km"; night/workday/holiday have no backend field.
class HiringRatesInput {
  const HiringRatesInput({
    required this.driverFirstHour,
    required this.driverPerExtraHour,
    required this.driverMinHours,
    required this.driverNightSurcharge,
    required this.driverTravelBasePerKm,
    required this.inspectorBaseFee,
    required this.inspectorWrittenReport,
  });

  final int driverFirstHour;
  final int driverPerExtraHour;
  final int driverMinHours;
  final int driverNightSurcharge;
  final int driverTravelBasePerKm;
  final int inspectorBaseFee;
  final int inspectorWrittenReport;
}

/// Shows the Hiring Rates bottom sheet with Driver / Inspector segments.
///
/// [onSaved] persists the entered values (PATCH); it may throw to keep the
/// sheet open (the caller shows the error toast). Closes only on success.
Future<void> showHiringRatesSheet(
  BuildContext context, {
  required HiringRates rates,
  required Future<void> Function(HiringRatesInput input) onSaved,
}) {
  final d = rates.driver;
  final i = rates.inspector;
  final firstHour = TextEditingController(text: '${d.firstHour}');
  final hourly = TextEditingController(text: '${d.hourly}');
  final minHours = TextEditingController(text: '${d.minHours}');
  final nightSurcharge = TextEditingController(text: '${d.nightSurcharge}');
  final travelBasePerKm = TextEditingController(text: '${d.travelDay}');
  final baseFee = TextEditingController(text: '${i.baseFee}');
  final reportFee = TextEditingController(text: '${i.reportFee}');

  final controllers = [
    firstHour,
    hourly,
    minHours,
    nightSurcharge,
    travelBasePerKm,
    baseFee,
    reportFee,
  ];

  return showAppBottomSheet<void>(
    context: context,
    title: 'Hiring rates',
    footer: _RatesFooter(
      onSaved: () => onSaved(HiringRatesInput(
        driverFirstHour: _parse(firstHour),
        driverPerExtraHour: _parse(hourly),
        driverMinHours: _parse(minHours),
        driverNightSurcharge: _parse(nightSurcharge),
        driverTravelBasePerKm: _parse(travelBasePerKm),
        inspectorBaseFee: _parse(baseFee),
        inspectorWrittenReport: _parse(reportFee),
      )),
    ),
    builder: (sheetContext) => _RatesBody(
      firstHour: firstHour,
      hourly: hourly,
      minHours: minHours,
      nightSurcharge: nightSurcharge,
      travelBasePerKm: travelBasePerKm,
      baseFee: baseFee,
      reportFee: reportFee,
    ),
  ).whenComplete(() {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

int _parse(TextEditingController c) =>
    double.tryParse(c.text.trim())?.round() ?? 0;

// ── Footer ────────────────────────────────────────────────────────────────────

class _RatesFooter extends StatefulWidget {
  const _RatesFooter({required this.onSaved});

  final Future<void> Function() onSaved;

  @override
  State<_RatesFooter> createState() => _RatesFooterState();
}

class _RatesFooterState extends State<_RatesFooter> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            kind: AppButtonKind.secondary,
            full: true,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AppButton(
            label: _saving ? 'Saving…' : 'Save',
            full: true,
            disabled: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _RatesBody extends StatefulWidget {
  const _RatesBody({
    required this.firstHour,
    required this.hourly,
    required this.minHours,
    required this.nightSurcharge,
    required this.travelBasePerKm,
    required this.baseFee,
    required this.reportFee,
  });

  final TextEditingController firstHour;
  final TextEditingController hourly;
  final TextEditingController minHours;
  final TextEditingController nightSurcharge;
  final TextEditingController travelBasePerKm;
  final TextEditingController baseFee;
  final TextEditingController reportFee;

  @override
  State<_RatesBody> createState() => _RatesBodyState();
}

class _RatesBodyState extends State<_RatesBody> {
  String _seg = 'driver'; // 'driver' | 'inspector'

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
            Expanded(child: _RateField(label: 'First hour', controller: widget.firstHour, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Per extra hour', controller: widget.hourly, prefix: '₹')),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _RateField(label: 'Min hours', controller: widget.minHours, suffix: 'hrs')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Night surcharge', controller: widget.nightSurcharge, prefix: '₹')),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(child: _RateField(label: 'Travel · base per km', controller: widget.travelBasePerKm, prefix: '₹')),
            SizedBox(width: 12.w),
            const Expanded(child: SizedBox()),
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
            Expanded(child: _RateField(label: 'Base fee', controller: widget.baseFee, prefix: '₹')),
            SizedBox(width: 12.w),
            Expanded(child: _RateField(label: 'Written report', controller: widget.reportFee, prefix: '₹')),
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
