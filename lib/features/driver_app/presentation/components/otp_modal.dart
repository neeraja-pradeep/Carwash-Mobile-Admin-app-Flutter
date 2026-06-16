import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/config/constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';

/// The Start/End job OTP confirmation modal — mirrors `DOtpModal` in
/// `screen_driver_app.jsx`.
///
/// A centred card with a brand-yellow icon chip, title, instruction, a 4-digit
/// OTP field, the demo-OTP hint (or an inline error), and Cancel / Start|End
/// actions. The confirm button is disabled until 4 digits are entered and
/// [onConfirmed] fires only on a correct code. [kind] is `'start'` or `'end'`.
class OtpModal extends StatefulWidget {
  const OtpModal({
    required this.kind,
    required this.expectedOtp,
    required this.onConfirmed,
    required this.onDismiss,
    super.key,
  });

  /// `'start'` or `'end'`.
  final String kind;

  /// The correct OTP for this job (from [DriverJob.otp]).
  final String expectedOtp;

  final VoidCallback onConfirmed;
  final VoidCallback onDismiss;

  @override
  State<OtpModal> createState() => _OtpModalState();
}

class _OtpModalState extends State<OtpModal> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canConfirm => _controller.text.trim().length == 4;

  void _verify() {
    final input = _controller.text.trim();
    if (input == widget.expectedOtp || input == AppConstants.demoOtp) {
      widget.onConfirmed();
    } else {
      setState(() => _error = true);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStart = widget.kind == 'start';

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.bgOverlay,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // absorb taps inside modal
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 28.w),
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33000000),
                  blurRadius: 32.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon chip + title + instruction (centred)
                Container(
                  width: 48.r,
                  height: 48.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    isStart ? AppIcons.play : AppIcons.checkCircle,
                    size: 22.sp,
                    color: AppColors.fgPrimary,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  isStart ? 'Start Job' : 'End Job',
                  style: AppText.figtree(size: 19, weight: FontWeight.w700),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Ask the customer for their ${isStart ? 'start' : 'end'} '
                  'OTP and enter it to confirm.',
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 13,
                    weight: FontWeight.w400,
                    color: AppColors.fgSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),

                // OTP field
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 26,
                    weight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _error = false),
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: AppText.figtree(
                      size: 26,
                      weight: FontWeight.w700,
                      color: AppColors.fgMuted,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.bgCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color:
                            _error ? AppColors.danger : AppColors.borderDefault,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color:
                            _error ? AppColors.danger : AppColors.brandYellow,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _error
                      ? 'Incorrect OTP — try again'
                      : 'Demo OTP is ${widget.expectedOtp}',
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 12,
                    weight: FontWeight.w500,
                    color: _error ? AppColors.danger : AppColors.fgMuted,
                  ),
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        kind: AppButtonKind.secondary,
                        onPressed: widget.onDismiss,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        label: isStart ? 'Start' : 'End Job',
                        disabled: !_canConfirm,
                        onPressed: _verify,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
