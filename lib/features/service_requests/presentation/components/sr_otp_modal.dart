import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';

/// OTP verification modal for starting or ending a service-request job.
///
/// Mirrors `OtpModal` in `screen_servicereq.jsx`. The customer reads the OTP
/// to the driver/inspector who types it here. In the demo, the expected OTP
/// is shown as a hint.
class SrOtpModal extends StatefulWidget {
  const SrOtpModal({
    required this.mode,
    required this.expectedOtp,
    required this.onVerify,
    super.key,
  });

  /// `'start'` to begin the job, `'end'` to complete it.
  final String mode;

  /// The OTP stored on the request (demo hint).
  final String expectedOtp;

  /// Called when the user enters the correct OTP.
  final VoidCallback onVerify;

  @override
  State<SrOtpModal> createState() => _SrOtpModalState();
}

class _SrOtpModalState extends State<SrOtpModal> {
  final TextEditingController _controller = TextEditingController();
  bool _hasError = false;

  bool get _isStart => widget.mode == 'start';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    if (_controller.text == widget.expectedOtp) {
      widget.onVerify();
    } else {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        0,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),

          // Icon badge.
          Container(
            width: 48.r,
            height: 48.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandYellow,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              _isStart ? AppIcons.play : AppIcons.checkCircle,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 14.h),

          Text(
            _isStart ? 'Start Job' : 'End Job',
            style: AppText.figtree(size: 19, weight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),

          Text(
            'Ask the customer for their ${_isStart ? 'start' : 'end'} OTP '
            'and enter it to confirm.',
            textAlign: TextAlign.center,
            style: AppText.figtree(
              size: 13,
              weight: FontWeight.w400,
              color: AppColors.fgSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),

          // OTP input.
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            textAlign: TextAlign.center,
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits != v) {
                _controller.text = digits;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: digits.length),
                );
              }
              if (_hasError) setState(() => _hasError = false);
            },
            style: AppText.figtree(
              size: 26,
              weight: FontWeight.w700,
              letterSpacing: 5.w,
              color: AppColors.fgPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.bgCard,
              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _hasError
                      ? AppColors.danger
                      : AppColors.borderDefault,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _hasError ? AppColors.danger : AppColors.borderDefault,
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // Error / hint.
          SizedBox(
            height: 18.h,
            child: Text(
              _hasError
                  ? 'Incorrect OTP — try again'
                  : 'Demo · customer\'s OTP is ${widget.expectedOtp}',
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 12,
                weight: FontWeight.w500,
                color: _hasError ? AppColors.danger : AppColors.fgMuted,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Buttons.
          Row(
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
                  label: _isStart ? 'Start' : 'End Job',
                  full: true,
                  disabled: _controller.text.length != 4,
                  onPressed: _verify,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
