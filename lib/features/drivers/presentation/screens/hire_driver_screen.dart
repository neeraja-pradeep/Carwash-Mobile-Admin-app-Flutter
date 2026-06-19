import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';

import '../../domain/entities/field_driver.dart';
import '../components/documents_section.dart';

/// "Hire Driver" full-screen form. Pushed from [DriversScreen] FAB.
///
/// Sections: Personal (name/phone/email), Role (segmented + vehicle classes),
/// Driving License (number/expiry/verified toggle), Documents.
/// Footer: primary "Add Driver & Send Invite" button (disabled until name +
/// phone + licenseNo are filled).
/// Back: shows discard-changes confirm dialog if the form is dirty.
class HireDriverScreen extends StatefulWidget {
  const HireDriverScreen({super.key});

  @override
  State<HireDriverScreen> createState() => _HireDriverScreenState();
}

class _HireDriverScreenState extends State<HireDriverScreen> {
  // Form state
  String _name = '';
  String _phone = '';
  String _email = '';
  String _role = kDriverRoles.first;
  String _licenseNo = '';
  String _licenseExpiry = '';
  bool _verified = false;
  List<String> _classes = ['Hatchback', 'Sedan'];
  List<DriverDocument> _docs = [];

  bool get _valid =>
      _name.trim().isNotEmpty &&
      _phone.trim().length >= 10 &&
      _licenseNo.trim().isNotEmpty;

  bool get _dirty =>
      _name.isNotEmpty || _phone.isNotEmpty || _licenseNo.isNotEmpty;

  void _toggleClass(String c) {
    setState(() {
      if (_classes.contains(c)) {
        _classes = _classes.where((x) => x != c).toList();
      } else {
        _classes = [..._classes, c];
      }
    });
  }

  Future<void> _handleBack() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Discard new driver?',
      body: 'Your entered details will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    // ignore: use_build_context_synchronously
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context: context,
          title: 'Discard new driver?',
          body: 'Your entered details will be lost.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (discard && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                title: 'Hire Driver',
                subtitle: 'New team member',
                onBack: _handleBack,
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  // Info banner
                  _InfoBanner(),
                  SizedBox(height: 14.h),

                  // Personal section
                  _FormCard(
                    label: 'Personal',
                    children: [
                      _LabeledField(
                        label: 'Full name',
                        value: _name,
                        placeholder: 'As on license',
                        onChanged: (v) => setState(() => _name = v),
                      ),
                      _LabeledField(
                        label: 'Phone (sign-in number)',
                        value: _phone,
                        placeholder: '+91 …',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => setState(() => _phone = v),
                      ),
                      _LabeledField(
                        label: 'Email',
                        value: _email,
                        placeholder: 'name@email.com',
                        optional: true,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => setState(() => _email = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Role section
                  _FormCard(
                    label: 'Role',
                    children: [
                      // Role segmented chips
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          for (final r in kDriverRoles)
                            AppChip(
                              label: r
                                  .replaceAll(' driver', '')
                                  .replaceAll('Wash + hire', 'Wash+Hire'),
                              active: _role == r,
                              onTap: () => setState(() => _role = r),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Vehicle classes they can handle',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          for (final c in kVehicleTypes)
                            AppChip(
                              label: c,
                              active: _classes.contains(c),
                              onTap: () => _toggleClass(c),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Driving License section
                  _FormCard(
                    label: 'Driving License',
                    children: [
                      _LabeledField(
                        label: 'License number',
                        value: _licenseNo,
                        placeholder: 'KL04 …',
                        onChanged: (v) => setState(() => _licenseNo = v),
                      ),
                      _LabeledField(
                        label: 'Expiry (MM-YYYY)',
                        value: _licenseExpiry,
                        placeholder: '08-2029',
                        onChanged: (v) =>
                            setState(() => _licenseExpiry = v),
                      ),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as verified',
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Confirm you've checked the original",
                                style: AppText.figtree(
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                          _Toggle(
                            value: _verified,
                            onChanged: () =>
                                setState(() => _verified = !_verified),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Documents
                  DocumentsSection(
                    documents: _docs,
                    onChanged: (updated) =>
                        setState(() => _docs = updated),
                  ),
                ],
              ),
            ),

            // Sticky footer
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                  top: BorderSide(color: AppColors.borderSoft),
                ),
              ),
              child: AppButton(
                label: 'Add Driver & Send Invite',
                full: true,
                disabled: !_valid,
                onPressed: _valid
                    ? () {
                        AppToast.show(
                          context,
                          'Driver added · invite sent to $_phone',
                        );
                        context.pop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.message, size: 18.sp, color: AppColors.blueFg),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Saving sends an invite SMS to this number. The driver signs in to the Driver app with OTP — only numbers added here can sign in.',
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w500,
                color: AppColors.blueFg,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.figtree(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.fgSecondary,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 14.h),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: 14.h),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ── Labeled text field ────────────────────────────────────────────────────────

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.optional = false,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool optional;
  final TextInputType keyboardType;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppText.figtree(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.fgSecondary,
              ),
            ),
            if (widget.optional) ...[
              SizedBox(width: 6.w),
              Text(
                'optional',
                style: AppText.figtree(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: AppColors.fgMuted,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: AppText.figtree(
                size: 14.5,
                weight: FontWeight.w400,
                color: AppColors.fgMuted,
              ),
            ),
            style: AppText.figtree(size: 14.5, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

// ── Toggle ────────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: value ? AppColors.brandYellow : AppColors.borderDefault,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.r,
            height: 20.r,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
