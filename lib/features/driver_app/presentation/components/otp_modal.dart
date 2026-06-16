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
/// Shows a 4-digit OTP entry field. The caller provides [expectedOtp] and
/// [onConfirmed] (called only on correct entry). [kind] is `'start'` or
/// `'end'`.
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
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final input = _controller.text.trim();
    if (input == widget.expectedOtp || input == AppConstants.demoOtp) {
      widget.onConfirmed();
    } else {
      setState(() => _error = 'Incorrect OTP. Try again.');
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStart = widget.kind == 'start';
    final title = isStart ? 'Start Job' : 'End Job';
    final subtitle = isStart
        ? 'Enter the OTP from the customer to start this job.'
        : 'Enter the OTP from the customer to complete this job.';

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.bgOverlay,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // absorb taps inside modal
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(24.r),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppText.figtree(
                        size: 18,
                        weight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(
                        AppIcons.close,
                        size: 22.sp,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  style: AppText.figtree(
                    size: 13.5,
                    weight: FontWeight.w400,
                    color: AppColors.fgTertiary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20.h),

                // OTP field
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 28,
                    weight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '----',
                    hintStyle: AppText.figtree(
                      size: 28,
                      weight: FontWeight.w300,
                      color: AppColors.fgMuted,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: _error != null
                            ? AppColors.danger
                            : AppColors.borderDefault,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: _error != null
                            ? AppColors.danger
                            : AppColors.brandYellow,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _error!,
                    style: AppText.figtree(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
                ],

                SizedBox(height: 20.h),

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
                        label: 'Confirm',
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
