import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';

/// Login screen — Admin / Driver toggle (default = Driver).
///
/// DRIVER mode: phone → Send OTP → 4-digit OTP → Verify → driverToday.
/// ADMIN mode: phone + password → Sign In → dashboard.
/// Purely local state (StatefulWidget) — no Riverpod needed here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Mode ─────────────────────────────────────────────────────────────────
  /// `'driver'` or `'admin'`. Default = driver.
  String _mode = 'driver';

  // ── Driver OTP flow ──────────────────────────────────────────────────────
  final _phoneController =
      TextEditingController(text: '+91 97447 30021');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  String? _driverError;

  // ── Admin flow ───────────────────────────────────────────────────────────
  final _adminPhoneController =
      TextEditingController(text: '+91 98470 22119');
  final _adminPasswordController =
      TextEditingController(text: AppConstants.demoAdminPassword);
  bool _showPassword = false;
  bool _showForgotMessage = false;
  String? _adminError;

  // ── Registered driver phone numbers (non-suspended) ──────────────────────
  static const _registeredDrivers = {
    '+91 97447 30021', // Manoj Kumar
    '+91 90745 11882', // Sreejith P
    '+91 98951 67200', // Rahim Basheer (invited — allow login)
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (!_registeredDrivers.contains(phone)) {
      setState(() => _driverError =
          'This number is not registered as a driver. Please check and try again.');
      return;
    }
    setState(() {
      _driverError = null;
      _otpSent = true;
    });
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp == AppConstants.demoOtp) {
      context.go(Routes.driverToday);
    } else {
      setState(() => _driverError = 'Incorrect OTP. Try 1234.');
    }
  }

  void _handleAdminSignIn() {
    final password = _adminPasswordController.text;
    if (password == AppConstants.demoAdminPassword) {
      context.go(Routes.dashboard);
    } else {
      setState(() => _adminError = 'Incorrect password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48.h),

              // ── Brand lockup ─────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56.r,
                      height: 56.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppButton.brandGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x66D6B112),
                            blurRadius: 16.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        AppIcons.car,
                        size: 28.sp,
                        color: AppColors.fgPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      AppConstants.appName,
                      style: AppText.figtree(
                        size: 26,
                        weight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _mode == 'admin'
                          ? 'Operator Console'
                          : 'Driver Partner',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w400,
                        color: AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // ── Mode toggle ──────────────────────────────────────────────
              _ModeToggle(
                selected: _mode,
                onSelect: (m) => setState(() {
                  _mode = m;
                  _driverError = null;
                  _adminError = null;
                  _otpSent = false;
                  _otpController.clear();
                  _showForgotMessage = false;
                }),
              ),

              SizedBox(height: 24.h),

              // ── Form ─────────────────────────────────────────────────────
              if (_mode == 'driver') _buildDriverForm()
              else _buildAdminForm(),

              SizedBox(height: 48.h),

              // ── Footer ───────────────────────────────────────────────────
              Center(
                child: Text(
                  'Single-city operations · Alappuzha, Kerala',
                  style: AppText.figtree(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Center(
                child: Text(
                  'DriveDeck ${AppConstants.appVersion}',
                  style: AppText.figtree(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Driver form ───────────────────────────────────────────────────────────

  Widget _buildDriverForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _otpSent ? 'Enter OTP' : 'Sign in to continue',
          style: AppText.figtree(size: 20, weight: FontWeight.w700),
        ),
        SizedBox(height: 4.h),
        Text(
          _otpSent
              ? 'We sent a demo OTP to ${_phoneController.text}.'
              : 'Enter your registered mobile number.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 20.h),

        if (!_otpSent) ...[
          // Phone field
          _InputLabel(label: 'Mobile Number'),
          SizedBox(height: 6.h),
          _TextField(
            controller: _phoneController,
            hint: '+91 00000 00000',
            icon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            onSubmitted: (_) => _handleSendOtp(),
          ),
        ] else ...[
          // OTP field
          _InputLabel(label: 'OTP'),
          SizedBox(height: 6.h),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: AppText.figtree(
              size: 26,
              weight: FontWeight.w700,
              letterSpacing: 14,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _driverError = null),
            onSubmitted: (_) => _handleVerifyOtp(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '----',
              hintStyle: AppText.figtree(
                size: 26,
                weight: FontWeight.w300,
                color: AppColors.fgMuted,
                letterSpacing: 14,
              ),
              filled: true,
              fillColor: AppColors.bgInput,
              contentPadding: EdgeInsets.symmetric(
                vertical: 16.h,
                horizontal: 12.w,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _driverError != null
                      ? AppColors.danger
                      : AppColors.borderDefault,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _driverError != null
                      ? AppColors.danger
                      : AppColors.brandYellow,
                  width: 2,
                ),
              ),
            ),
          ),
        ],

        // Error
        if (_driverError != null) ...[
          SizedBox(height: 8.h),
          Text(
            _driverError!,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ],

        SizedBox(height: 20.h),

        if (!_otpSent)
          AppButton(
            label: 'Send OTP',
            full: true,
            onPressed: _handleSendOtp,
          )
        else ...[
          AppButton(
            label: 'Verify & Sign In',
            full: true,
            onPressed: _handleVerifyOtp,
          ),
          SizedBox(height: 12.h),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _otpSent = false;
                _otpController.clear();
                _driverError = null;
              }),
              child: Text(
                'Change number',
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.fgTertiary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Admin form ────────────────────────────────────────────────────────────

  Widget _buildAdminForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in to continue',
          style: AppText.figtree(size: 20, weight: FontWeight.w700),
        ),
        SizedBox(height: 4.h),
        Text(
          'Enter your operator credentials.',
          style: AppText.figtree(
            size: 13.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
          ),
        ),
        SizedBox(height: 20.h),

        // Phone
        _InputLabel(label: 'Mobile Number'),
        SizedBox(height: 6.h),
        _TextField(
          controller: _adminPhoneController,
          hint: '+91 00000 00000',
          icon: AppIcons.phone,
          keyboardType: TextInputType.phone,
        ),

        SizedBox(height: 14.h),

        // Password
        _InputLabel(label: 'Password'),
        SizedBox(height: 6.h),
        _PasswordField(
          controller: _adminPasswordController,
          visible: _showPassword,
          onToggleVisibility: () =>
              setState(() => _showPassword = !_showPassword),
          onSubmitted: (_) => _handleAdminSignIn(),
          hasError: _adminError != null,
        ),

        // Error + forgot
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_adminError != null)
              Expanded(
                child: Text(
                  _adminError!,
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: AppColors.danger,
                  ),
                ),
              )
            else
              const Spacer(),
            GestureDetector(
              onTap: () =>
                  setState(() => _showForgotMessage = !_showForgotMessage),
              child: Text(
                'Forgot password?',
                style: AppText.figtree(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppColors.fgSecondary,
                ),
              ),
            ),
          ],
        ),

        if (_showForgotMessage) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              'Contact your co-founder to reset.',
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.fgSecondary,
              ),
            ),
          ),
        ],

        SizedBox(height: 20.h),

        AppButton(
          label: 'Sign In',
          full: true,
          onPressed: _handleAdminSignIn,
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          _ModePill(
            label: 'Driver',
            active: selected == 'driver',
            onTap: () => onSelect('driver'),
          ),
          _ModePill(
            label: 'Admin',
            active: selected == 'admin',
            onTap: () => onSelect('admin'),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          margin: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            color: active ? AppColors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0x14000000),
                      blurRadius: 4.r,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.figtree(
              size: 14,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.fgPrimary : AppColors.fgTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppText.figtree(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.fgSecondary,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: AppText.figtree(size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.figtree(
          size: 15,
          weight: FontWeight.w400,
          color: AppColors.fgMuted,
        ),
        prefixIcon:
            Icon(icon, size: 18.sp, color: AppColors.fgTertiary),
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding:
            EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: AppColors.brandYellow, width: 2),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.onToggleVisibility,
    this.onSubmitted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      onSubmitted: onSubmitted,
      style: AppText.figtree(size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: AppText.figtree(
          size: 15,
          weight: FontWeight.w400,
          color: AppColors.fgMuted,
        ),
        prefixIcon: Icon(AppIcons.gear,
            size: 18.sp, color: AppColors.fgTertiary),
        suffixIcon: GestureDetector(
          onTap: onToggleVisibility,
          child: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18.sp,
            color: AppColors.fgTertiary,
          ),
        ),
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding:
            EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.danger : AppColors.borderDefault,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.danger : AppColors.brandYellow,
            width: 2,
          ),
        ),
      ),
    );
  }
}
