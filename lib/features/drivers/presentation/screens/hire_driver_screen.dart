import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_button.dart';
import 'package:new_flutter_project/core/widgets/app_chip.dart';
import 'package:new_flutter_project/core/widgets/app_dialog.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';
import 'package:new_flutter_project/core/widgets/top_bar.dart';
import 'package:new_flutter_project/core/constants/app_options.dart';

import '../../application/providers/drivers_providers.dart';
import '../../domain/entities/field_driver.dart';
import '../../infrastructure/models/driver_response_model.dart';
import '../components/documents_section.dart';

/// "Hire Driver" / "Edit Driver" full-screen form.
///
/// Add mode (no [driver]) — pushed from the [DriversScreen] FAB.
/// Edit mode ([driver] set) — pushed from the driver detail 3-dot "Edit profile";
/// fields are prefilled and the copy switches to "Edit Driver" / "Save Changes".
///
/// Sections: Personal (name/phone/email), Role (segmented + vehicle classes),
/// Driving License (number/expiry/verified toggle), Documents.
/// Footer: primary CTA, disabled until name + phone + licenseNo are filled.
/// Back: shows a discard confirm dialog if the form is dirty.
class HireDriverScreen extends ConsumerStatefulWidget {
  const HireDriverScreen({this.driver, this.isInspector = false, super.key});

  /// When non-null the form is in edit mode and prefilled from this driver.
  final FieldDriver? driver;

  /// When true (add mode) the form creates an inspector instead of a driver.
  final bool isInspector;

  @override
  ConsumerState<HireDriverScreen> createState() => _HireDriverScreenState();
}

class _HireDriverScreenState extends ConsumerState<HireDriverScreen> {
  // Form state
  late String _name;
  late String _phone;
  late String _email;
  late String _role;
  late String _licenseNo;
  late String _licenseExpiry;
  late bool _verified;
  late List<String> _classes;
  late List<DriverDocument> _docs;
  bool _submitting = false;

  bool get _isEdit => widget.driver != null;

  /// Drivers tab edits/creates drivers; the inspector flag is set on add and
  /// inferred on edit from the worker's role label.
  bool get _isInspector => _isEdit
      ? (widget.driver!.subRole == null &&
          widget.driver!.role.toLowerCase().contains('inspector'))
      : widget.isInspector;

  /// Role labels offered for drivers (excludes the "Inspector" pseudo-role).
  List<String> get _roleOptions =>
      kDriverRoles.where((r) => r != 'Inspector').toList();

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _name = d?.name ?? '';
    _phone = d?.phone ?? '';
    _email = d?.email ?? '';
    _role = d != null
        ? roleLabelFromSubRole(d.subRole)
        : _roleOptions.first;
    _licenseNo = d?.license.number ?? '';
    _licenseExpiry = d?.license.expiry ?? '';
    _verified = d?.license.verified ?? false;
    _classes = d != null ? [...d.vehicleClasses] : ['Hatchback', 'Sedan'];
    _docs = d != null ? [...d.documents] : [];
  }

  bool get _valid =>
      _name.trim().isNotEmpty &&
      _phone.trim().length >= 10 &&
      _licenseNo.trim().isNotEmpty;

  // Editing an existing driver is always treated as dirty (mirrors the design).
  bool get _dirty =>
      _isEdit || _name.isNotEmpty || _phone.isNotEmpty || _licenseNo.isNotEmpty;

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
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: _isEdit ? 'Discard changes?' : 'Discard new driver?',
      body: 'Your entered details will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Converts the form's `MM-YYYY` expiry to an ISO `YYYY-MM-DD` date (assumes
  /// the 1st of the month) — required by PATCH. Returns the raw value if it is
  /// not in `MM-YYYY` form (e.g. already ISO or empty).
  String? _expiryForPatch(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2})-(\d{4})$').firstMatch(v);
    if (m != null) {
      final month = m.group(1)!.padLeft(2, '0');
      return '${m.group(2)}-$month-01';
    }
    return v;
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() => _submitting = true);
    final mutations = ref.read(driverMutationsProvider);
    final isInspector = _isInspector;
    try {
      if (_isEdit) {
        // Edit is reachable from the driver detail only (inspectors are
        // list-only), so this always patches a driver.
        await mutations.updateDriver(
          widget.driver!.id,
          fullName: _name.trim(),
          email: _email.trim(),
          subRole: subRoleFromLabel(_role),
          vehicleClasses: _classes,
          licenseNumber: _licenseNo.trim(),
          licenseExpiry: _expiryForPatch(_licenseExpiry),
          licenseVerified: _verified,
          phone: _phone.trim(),
        );
        if (!mounted) return;
        AppToast.show(context, 'Driver updated');
      } else if (isInspector) {
        await mutations.hireInspector(
          fullName: _name.trim(),
          phone: _phone.trim(),
          email: _email.trim().isEmpty ? null : _email.trim(),
          vehicleClasses: _classes,
          licenseNumber: _licenseNo.trim(),
          licenseExpiry: _licenseExpiry.trim(),
          licenseVerified: _verified,
        );
        if (!mounted) return;
        AppToast.show(context, 'Inspector added');
      } else {
        await mutations.hireDriver(
          fullName: _name.trim(),
          phone: _phone.trim(),
          email: _email.trim().isEmpty ? null : _email.trim(),
          subRole: subRoleFromLabel(_role),
          vehicleClasses: _classes,
          licenseNumber: _licenseNo.trim(),
          licenseExpiry: _licenseExpiry.trim(),
          licenseVerified: _verified,
        );
        if (!mounted) return;
        AppToast.show(context, 'Driver added');
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: _isEdit
                  ? 'Edit Driver'
                  : (_isInspector ? 'Add Inspector' : 'Hire Driver'),
              subtitle: _isEdit ? widget.driver!.name : 'New team member',
              onBack: _handleBack,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  // Info banner — add mode only
                  if (!_isEdit) ...[
                    _InfoBanner(),
                    SizedBox(height: 14.h),
                  ],

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
                      // Role segmented chips (drivers only — inspectors have
                      // no sub_role).
                      if (!_isInspector) ...[
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final r in _roleOptions)
                              AppChip(
                                label: r
                                    .replaceAll(' driver', '')
                                    .replaceAll('Wash + hire', 'Wash+Hire'),
                                active: _role == r,
                                onTap: () => setState(() => _role = r),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                      ],
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
                        onChanged: (v) => setState(() => _licenseExpiry = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Documents — real uploads in edit mode (worker exists);
                  // local-only in add mode (no id yet).
                  DocumentsSection(
                    documents: _docs,
                    onChanged: (updated) => setState(() => _docs = updated),
                    workerId: _isEdit ? widget.driver!.id : null,
                    isInspector: _isInspector,
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
                label: _isEdit
                    ? 'Save Changes'
                    : (_isInspector
                        ? 'Add Inspector'
                        : 'Add Driver & Send Invite'),
                full: true,
                disabled: !_valid || _submitting,
                onPressed: (_valid && !_submitting) ? _submit : null,
              ),
            ),
          ],
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
