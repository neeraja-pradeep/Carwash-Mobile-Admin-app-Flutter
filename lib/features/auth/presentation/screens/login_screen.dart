import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/auth/auth_session_signal.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';

/// Login screen — Admin / Driver toggle (default = Driver).
///
/// DRIVER mode: phone → Send OTP → 6-digit OTP → Verify → driverToday.
/// ADMIN mode: username + password → Sign In → dashboard.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── Mode ─────────────────────────────────────────────────────────────────
  /// `'driver'` or `'admin'`. Default = driver.
  String _mode = 'driver';

  // ── Driver OTP flow ──────────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  String? _driverError;

  // ── Driver username/password flow ─────────────────────────────────────────
  bool _driverUsePassword = false;
  final _driverUsernameController = TextEditingController();
  final _driverPasswordController = TextEditingController();
  bool _driverShowPassword = false;
  String? _driverPasswordError;

  // ── Admin flow ───────────────────────────────────────────────────────────
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showForgotMessage = false;
  String? _adminError;

  @override
  void initState() {
    super.initState();
    // Explain the bounce when the router sent us here because the server
    // rejected the session, rather than the operator signing out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AuthSessionSignal.instance.consumeExpiredFlag()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session expired. Please sign in again.'),
        ),
      );
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _driverUsernameController.dispose();
    _driverPasswordController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _driverError = 'Enter your phone number to continue.');
      return;
    }
    if (!PhoneNumber.isValid(phone)) {
      setState(() => _driverError =
          PhoneNumber.errorFor(phone) ?? 'Enter a valid mobile number.');
      return;
    }

    setState(() => _driverError = null);

    try {
      ref.read(authStateProvider.notifier).sendOtp(
            // E.164 — the same shape the admin console registers the driver
            // with, so the server's lookup finds them.
            phone: PhoneNumber.e164(phone),
            role: 'driver',
          );
      // Don't set _otpSent here — wait for state listener to handle OtpSent state
    } catch (e) {
      setState(() => _driverError = 'Error: ${e.toString()}');
    }
  }

  void _handleVerifyOtp() {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _driverError = 'OTP must be 6 digits.');
      return;
    }

    try {
      ref.read(authStateProvider.notifier).verifyOtp(
            // Must match the number send-otp was called with, or the server
            // treats this as a different person.
            phone: PhoneNumber.e164(phone),
            otpCode: otp,
            role: 'driver',
          );
    } catch (e) {
      setState(() => _driverError = 'Error: ${e.toString()}');
    }
  }

  void _handleDriverPasswordSignIn() {
    final username = _driverUsernameController.text.trim();
    final password = _driverPasswordController.text.trim();

    if (username.isEmpty) {
      setState(() => _driverPasswordError = 'Enter your username to continue.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _driverPasswordError = 'Enter your password to continue.');
      return;
    }

    try {
      ref.read(authStateProvider.notifier).login(
            username: username,
            password: password,
            validateAdminRole: false,
          );
    } catch (e) {
      setState(() => _driverPasswordError = 'Error: ${e.toString()}');
    }
  }

  void _handlePasswordChanged(String _) {
    if (_adminError != null) {
      setState(() => _adminError = null);
    }
  }

  void _handleAdminSignIn() {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (username.isEmpty) {
      setState(() => _adminError = 'Enter your username to continue.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _adminError = 'Enter your password to continue.');
      return;
    }

    try {
      ref.read(authStateProvider.notifier).login(
            username: username,
            password: password,
            validateAdminRole: true,
          );
    } catch (e) {
      setState(() => _adminError = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, state) {
      if (!mounted) return;
      if (state is AuthSuccess) {
        // `_identify` has already opened the router's auth gate by this point,
        // so these targets are reachable.
        if (state.user.role == 'driver') {
          context.go(Routes.driverToday);
        } else {
          context.go(Routes.dashboard);
        }
      } else if (state is AuthError) {
        if (_mode == 'driver') {
          if (_driverUsePassword) {
            setState(() => _driverPasswordError = state.message);
          } else {
            setState(() => _driverError = state.message);
          }
        } else {
          setState(() => _adminError = state.message);
        }
      } else if (state is OtpSent) {
        setState(() => _otpSent = true);
      }
    });

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
                  _driverPasswordError = null;
                  _driverUsePassword = false;
                  _adminError = null;
                  _otpSent = false;
                  _otpController.clear();
                  _driverUsernameController.clear();
                  _driverPasswordController.clear();
                  _adminUsernameController.clear();
                  _adminPasswordController.clear();
                  _showForgotMessage = false;
                }),
              ),

              SizedBox(height: 24.h),

              // ── Form ─────────────────────────────────────────────────────
              if (_mode == 'driver') _buildDriverForm() else _buildAdminForm(),

              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Driver form ───────────────────────────────────────────────────────────

  Widget _buildDriverForm() {
    if (_driverUsePassword) {
      return _buildDriverPasswordForm();
    }
    return _buildDriverOtpForm();
  }

  Widget _buildDriverOtpForm() {
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
              ? 'Sent to ${PhoneNumber.dialCode} ${_phoneController.text}.'
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
            // The field holds the ten national digits; +91 is fixed, so the
            // number sent here matches the one the admin registered.
            hint: '00000 00000',
            prefixText: PhoneNumber.dialCode,
            icon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: const [PhoneNumberInputFormatter()],
            onChanged: (_) => setState(() => _driverError = null),
            onSubmitted: (_) => _handleSendOtp(),
          ),
          SizedBox(height: 12.h),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _driverUsePassword = true;
                _driverError = null;
              }),
              child: Text(
                'Or login via username and password',
                style: AppText.figtree(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.fgSecondary,
                ),
              ),
            ),
          ),
        ] else ...[
          // OTP field
          _InputLabel(label: 'OTP'),
          SizedBox(height: 6.h),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppText.figtree(
              size: 26,
              weight: FontWeight.w700,
              letterSpacing: 10,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _driverError = null),
            onSubmitted: (_) => _handleVerifyOtp(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: AppText.figtree(
                size: 26,
                weight: FontWeight.w300,
                color: AppColors.fgMuted,
                letterSpacing: 10,
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

        // Error hint
        if (_driverError != null) ...[
          SizedBox(height: 8.h),
          _HintLine(error: _driverError, hint: ''),
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
            disabled: _otpController.text.length != 6,
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

  Widget _buildDriverPasswordForm() {
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
          'Use your username and password to sign in.',
          style: AppText.figtree(
            size: 14.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28.h),

        // Username field
        _InputLabel(label: 'Username'),
        SizedBox(height: 7.h),
        _TextField(
          controller: _driverUsernameController,
          hint: 'Enter your username',
          icon: Icons.person_outline,
          onSubmitted: (_) => _handleDriverPasswordSignIn(),
        ),

        SizedBox(height: 18.h),

        // Password field
        _InputLabel(label: 'Password'),
        SizedBox(height: 7.h),
        _PasswordField(
          controller: _driverPasswordController,
          visible: _driverShowPassword,
          onToggleVisibility: () =>
              setState(() => _driverShowPassword = !_driverShowPassword),
          onChanged: (_) => setState(() => _driverPasswordError = null),
          onSubmitted: (_) => _handleDriverPasswordSignIn(),
          hasError: _driverPasswordError != null,
        ),

        // Error hint
        if (_driverPasswordError != null) ...[
          SizedBox(height: 6.h),
          _HintLine(error: _driverPasswordError, hint: ''),
        ],

        SizedBox(height: 20.h),

        AppButton(
          label: 'Sign In',
          full: true,
          onPressed: _handleDriverPasswordSignIn,
        ),

        SizedBox(height: 12.h),

        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _driverUsePassword = false;
              _driverPasswordError = null;
              _driverUsernameController.clear();
              _driverPasswordController.clear();
              _driverShowPassword = false;
            }),
            child: Text(
              'Or login via OTP',
              style: AppText.figtree(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
          ),
        ),
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
          'Enter your credentials to access the operator console.',
          style: AppText.figtree(
            size: 14.5,
            weight: FontWeight.w400,
            color: AppColors.fgTertiary,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28.h),

        // Username
        _InputLabel(label: 'Username'),
        SizedBox(height: 7.h),
        _TextField(
          controller: _adminUsernameController,
          hint: 'Enter your username',
          icon: Icons.person_outline,
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
          hasError: _adminError != null,
        ),

        // Error hint + forgot password
        SizedBox(height: 6.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _adminError != null
                  ? _HintLine(error: _adminError, hint: '')
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: 8.w),
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
              'No self-serve reset. Contact your administrator to reset your password.',
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
          label: 'Sign In',
          full: true,
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
    this.onChanged,
    this.inputFormatters,
    this.prefixText,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  /// A fixed, non-editable lead-in shown after the icon (e.g. `+91`). Never
  /// part of the controller's text — the caller adds it when building the
  /// payload, so what is typed and what is sent can't drift apart.
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: AppText.figtree(size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.figtree(
          size: 15,
          weight: FontWeight.w400,
          color: AppColors.fgMuted,
        ),
        prefixIcon: prefixText == null
            ? Icon(icon, size: 18.sp, color: AppColors.fgTertiary)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 14.w),
                  Icon(icon, size: 18.sp, color: AppColors.fgTertiary),
                  SizedBox(width: 8.w),
                  Text(
                    prefixText!,
                    style: AppText.figtree(size: 15, weight: FontWeight.w600),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 1,
                    height: 18.h,
                    color: AppColors.borderDefault,
                  ),
                  SizedBox(width: 10.w),
                ],
              ),
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
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
