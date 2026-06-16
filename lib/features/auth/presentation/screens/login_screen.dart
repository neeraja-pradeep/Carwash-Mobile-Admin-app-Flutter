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
  final _phoneController = TextEditingController(text: '+91 97447 30021');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  String? _driverError;

  // ── Admin flow ───────────────────────────────────────────────────────────
  final _adminPhoneController = TextEditingController(text: '+91 98470 22119');
  final _adminPasswordController =
      TextEditingController(text: AppConstants.demoAdminPassword);
  bool _showPassword = false;
  bool _showForgotMessage = false;
  String? _adminError;

  /// Failed sign-in attempts. At [_lockThreshold] the account is "locked" for
  /// the demo (mirrors the lockout state in screen_login.jsx).
  int _adminAttempts = 0;
  static const int _lockThreshold = 5;

  bool get _adminLocked => _adminAttempts >= _lockThreshold;

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
          "This number isn't registered. Ask your admin to add you.");
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
      setState(() => _driverError = 'Incorrect OTP. Demo OTP is 1234.');
    }
  }

  /// Editing the password clears any demo lock so a reviewer is never trapped
  /// (matches the `onPwd` behaviour in screen_login.jsx).
  void _handlePasswordChanged(String _) {
    if (_adminError != null || _adminAttempts != 0) {
      setState(() {
        _adminError = null;
        _adminAttempts = 0;
      });
    }
  }

  void _handleAdminSignIn() {
    if (_adminLocked) return;
    final password = _adminPasswordController.text;
    if (password.isEmpty) {
      setState(() => _adminError = 'Enter your password to continue.');
      return;
    }
    if (password == AppConstants.demoAdminPassword) {
      setState(() => _adminError = null);
      context.go(Routes.dashboard);
      return;
    }
    setState(() {
      _adminAttempts++;
      final left = _lockThreshold - _adminAttempts;
      _adminError = _adminLocked
          ? 'Too many attempts. Locked for 15 minutes.'
          : 'Incorrect password. $left attempt${left == 1 ? '' : 's'} left.';
    });
  }

  void _resetLock() {
    setState(() {
      _adminAttempts = 0;
      _adminError = null;
    });
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
                      _mode == 'admin' ? AppConstants.appName : 'Drivey',
                      style: AppText.figtree(
                        size: 25,
                        weight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      (_mode == 'admin' ? 'Operator Console' : 'Driver Partner')
                          .toUpperCase(),
                      style: AppText.figtree(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.fgTertiary,
                        letterSpacing: 0.18 * 10.5,
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
                  _adminAttempts = 0;
                  _otpSent = false;
                  _otpController.clear();
                  _showForgotMessage = false;
                }),
              ),

              SizedBox(height: 24.h),

              // ── Form ─────────────────────────────────────────────────────
              if (_mode == 'driver') _buildDriverForm() else _buildAdminForm(),

              SizedBox(height: 48.h),

              // ── Footer ───────────────────────────────────────────────────
              Center(
                child: Text(
                  _mode == 'admin'
                      ? 'Single-city operations · Alappuzha, Kerala'
                      : 'Drivey Driver · Alappuzha',
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.fgMuted,
                  ),
                ),
              ),
              if (_mode == 'admin') ...[
                SizedBox(height: 4.h),
                Center(
                  child: Text(
                    'DriveDeck Operator v0.1',
                    style: AppText.figtree(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
              ],
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
          _otpSent ? 'Enter OTP' : 'Sign in',
          style: AppText.figtree(
              size: 26, weight: FontWeight.w700, letterSpacing: -0.6),
        ),
        SizedBox(height: 6.h),
        Text(
          _otpSent
              ? 'Sent to ${_phoneController.text}.'
              : "Use the mobile number your admin registered. "
                  "We'll send a one-time code.",
          style: AppText.figtree(
            size: 14.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28.h),

        if (!_otpSent) ...[
          // Phone field
          _InputLabel(label: 'Mobile number'),
          SizedBox(height: 7.h),
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

        // Error / demo hint
        SizedBox(height: 8.h),
        _HintLine(
          error: _driverError,
          hint: _otpSent
              ? 'Demo OTP is 1234'
              : "Demo · Manoj's number is pre-filled",
        ),

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
            disabled: _otpController.text.length != 4,
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
          style: AppText.figtree(
              size: 26, weight: FontWeight.w700, letterSpacing: -0.6),
        ),
        SizedBox(height: 6.h),
        Text(
          "Run today's washes, assignments, and refunds from one place.",
          style: AppText.figtree(
            size: 14.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28.h),

        // Phone
        _InputLabel(label: 'Phone number'),
        SizedBox(height: 7.h),
        _TextField(
          controller: _adminPhoneController,
          hint: '+91 00000 00000',
          icon: AppIcons.phone,
          keyboardType: TextInputType.phone,
        ),

        SizedBox(height: 18.h),

        // Password
        _InputLabel(label: 'Password'),
        SizedBox(height: 7.h),
        _PasswordField(
          controller: _adminPasswordController,
          visible: _showPassword,
          onToggleVisibility: () =>
              setState(() => _showPassword = !_showPassword),
          onChanged: _handlePasswordChanged,
          onSubmitted: (_) => _handleAdminSignIn(),
          hasError: _adminError != null && !_adminLocked,
        ),

        // Error / demo hint  +  forgot / reset-lock
        SizedBox(height: 6.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _HintLine(
                error: _adminError,
                hint: 'Demo · password pre-filled, just tap Sign In',
              ),
            ),
            SizedBox(width: 8.w),
            if (_adminLocked)
              GestureDetector(
                onTap: _resetLock,
                child: Text(
                  'Reset lock',
                  style: AppText.figtree(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              )
            else
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
              'No self-serve reset in v0.1. Contact your co-founder to reset '
              'your password.',
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.fgSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],

        SizedBox(height: 14.h),

        AppButton(
          label: _adminLocked ? 'Locked — try later' : 'Sign In',
          full: true,
          disabled: _adminLocked,
          onPressed: _handleAdminSignIn,
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// One-line error-or-hint row under a field. Shows [error] (danger colour with
/// an alert glyph) when non-null, otherwise the muted [hint] — mirrors the
/// error/hint line in screen_login.jsx.
class _HintLine extends StatelessWidget {
  const _HintLine({required this.error, required this.hint});

  final String? error;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasError) ...[
          Icon(AppIcons.alert, size: 14.sp, color: AppColors.danger),
          SizedBox(width: 5.w),
        ],
        Flexible(
          child: Text(
            hasError ? error! : hint,
            style: AppText.figtree(
              size: 12.5,
              weight: FontWeight.w500,
              color: hasError ? AppColors.danger : AppColors.fgMuted,
            ),
          ),
        ),
      ],
    );
  }
}

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
        prefixIcon: Icon(icon, size: 18.sp, color: AppColors.fgTertiary),
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
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
          borderSide: const BorderSide(color: AppColors.brandYellow, width: 2),
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
    this.onChanged,
    this.onSubmitted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppText.figtree(size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Enter password',
        hintStyle: AppText.figtree(
          size: 15,
          weight: FontWeight.w400,
          color: AppColors.fgMuted,
        ),
        prefixIcon:
            Icon(AppIcons.gear, size: 18.sp, color: AppColors.fgTertiary),
        suffixIcon: GestureDetector(
          onTap: onToggleVisibility,
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Text(
              visible ? 'Hide' : 'Show',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
          ),
        ),
        suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
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
