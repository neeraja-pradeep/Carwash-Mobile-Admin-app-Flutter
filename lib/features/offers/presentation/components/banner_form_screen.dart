import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../application/providers/offers_providers.dart';
import '../../domain/entities/offer_banner.dart';
import 'form_helpers.dart';

/// Add / Edit banner form — pushed intra-module via Navigator.
///
/// Writes to `/api/shop/v1/promotions/`. Artwork goes up as a multipart
/// `image` file and comes back as a CDN `image_url`; there is no way to set a
/// URL directly.
class BannerFormScreen extends ConsumerStatefulWidget {
  const BannerFormScreen({this.banner, super.key});

  /// Null when creating a new banner.
  final OfferBanner? banner;

  @override
  ConsumerState<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends ConsumerState<BannerFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _badgeCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _orderCtrl;
  late String _placement;
  late bool _active;
  DateTime? _from;
  DateTime? _to;

  bool _saving = false;

  /// Filesystem path of an image picked on this device, or null when the form
  /// is still showing the banner's existing artwork (or nothing at all).
  String? _imagePath;

  /// Set when the admin clears the existing artwork without picking a
  /// replacement — this is what sends an empty `image` on save so the server
  /// deletes the CDN file, as opposed to omitting it and keeping the artwork.
  bool _imageCleared = false;

  bool get _isEdit => widget.banner != null;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _badgeCtrl = TextEditingController(text: b?.badgeText ?? '');
    _linkCtrl = TextEditingController(text: b?.deepLink ?? '');
    _orderCtrl = TextEditingController(text: '${b?.displayOrder ?? 0}');
    _placement = b?.placement ?? 'home_hero';
    _active = b?.isActive ?? true;
    _from = b?.startsAt;
    _to = b?.endsAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _badgeCtrl.dispose();
    _linkCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  // ─── Image ──────────────────────────────────────────────────────────────────

  /// The artwork the preview should show: a freshly picked file wins, then the
  /// banner's CDN image unless it has been cleared.
  ImageProvider? get _previewImage {
    final picked = _imagePath;
    if (picked != null) return FileImage(File(picked));
    if (_imageCleared) return null;
    final existing = widget.banner?.imageUrl;
    if (existing == null || existing.trim().isEmpty) return null;
    return NetworkImage(existing);
  }

  bool get _hasImage => _previewImage != null;

  /// Picks banner artwork from the device gallery.
  ///
  /// Gallery only — a promo banner is designed artwork, not something shot on
  /// the spot, and it keeps the app clear of a camera permission it declares
  /// nowhere else.
  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _imagePath = file.path;
        _imageCleared = false;
      });
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open gallery');
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
      _imageCleared = true;
    });
  }

  // ─── Dates ──────────────────────────────────────────────────────────────────

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}-'
        '${_month(d.month)}-${d.year}';
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _from : _to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        // Start of day for the window start.
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        // End of day, so a banner stays live through its final date.
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  // ─── Save ───────────────────────────────────────────────────────────────────

  /// Client-side checks mirroring the serializer, so an obvious mistake costs a
  /// toast rather than a round trip.
  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Give the banner a title.';
    if (_from == null || _to == null) return 'Please set both validity dates.';
    if (!_to!.isAfter(_from!)) return 'End date must be after start date.';
    return null;
  }

  /// `coupon` is deliberately absent: the form's single "Links to" control maps
  /// to `deep_link`, and omitting `coupon` leaves any linked coupon untouched
  /// rather than clearing it.
  Map<String, dynamic> _buildPayload() => {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'badge_text': _badgeCtrl.text.trim(),
        'deep_link': _linkCtrl.text.trim(),
        'placement': _placement,
        'starts_at': _from!.toUtc().toIso8601String(),
        'ends_at': _to!.toUtc().toIso8601String(),
        'is_active': _active,
        'display_order': int.tryParse(_orderCtrl.text.trim()) ?? 0,
      };

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      AppToast.show(context, error);
      return;
    }

    setState(() => _saving = true);
    final actions = ref.read(bannerActionsProvider);
    try {
      if (_isEdit) {
        await actions.update(
          widget.banner!.id,
          _buildPayload(),
          imagePath: _imagePath,
          removeImage: _imageCleared && _imagePath == null,
        );
      } else {
        await actions.create(_buildPayload(), imagePath: _imagePath);
      }
      if (!mounted) return;
      AppToast.show(context, _isEdit ? 'Banner saved' : 'Banner created');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Delete this banner?',
      body: 'It will disappear from the customer Home, and its image is '
          "removed from the CDN. This can't be undone.",
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(bannerActionsProvider).delete(widget.banner!.id);
      if (!mounted) return;
      AppToast.show(context, 'Banner deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
              title: _isEdit ? 'Edit Banner' : 'Add Banner',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  OfferFCard(
                    label: 'Image',
                    children: [
                      _BannerImageField(
                        image: _previewImage,
                        onPick: _pickImage,
                        onRemove: _hasImage ? _removeImage : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Content',
                    children: [
                      OfferFInput(
                        label: 'Title',
                        controller: _titleCtrl,
                        placeholder: 'e.g. Up to 40% Off',
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Subtitle',
                        controller: _subtitleCtrl,
                        placeholder: 'Short supporting line',
                        optional: true,
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Badge text',
                        controller: _badgeCtrl,
                        placeholder: 'e.g. SPECIAL OFFER',
                        optional: true,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Validity',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Live from',
                              value: _fmt(_from),
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _DateField(
                              label: 'Live until',
                              value: _fmt(_to),
                              onTap: () => _pickDate(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  OfferFCard(
                    label: 'Placement & Link',
                    children: [
                      Text(
                        'Placement',
                        style: AppText.figtree(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.fgSecondary,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      OfferSegControl(
                        value: _placement,
                        options: const [
                          ('home_hero', 'Home — Hero'),
                          ('home_strip', 'Home — Strip'),
                        ],
                        onChanged: (v) => setState(() => _placement = v),
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Links to',
                        controller: _linkCtrl,
                        placeholder: 'Screen or URL opened on tap',
                        optional: true,
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Display order',
                        controller: _orderCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active',
                                style: AppText.figtree(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _active ? 'Visible in app' : 'Hidden',
                                style: AppText.figtree(
                                  size: 12,
                                  color: AppColors.fgTertiary,
                                ),
                              ),
                            ],
                          ),
                          OfferToggle(
                            on: _active,
                            onTap: () => setState(() => _active = !_active),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isEdit) ...[
                    SizedBox(height: 14.h),
                    AppButton(
                      label: 'Delete banner',
                      kind: AppButtonKind.danger,
                      full: true,
                      disabled: _saving,
                      onPressed: _saving ? null : _delete,
                    ),
                  ],
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: AppButton(
            label: _saving
                ? 'Saving…'
                : (_isEdit ? 'Save Changes' : 'Create Banner'),
            full: true,
            disabled: !_valid || _saving,
            onPressed: (_valid && !_saving) ? _submit : null,
          ),
        ),
      ),
    );
  }
}

/// The banner artwork slot: a 16:9-ish tappable tile that shows the chosen
/// image, or an upload prompt when there is none.
///
/// [onRemove] is null while the slot is empty, which hides the clear button.
class _BannerImageField extends StatelessWidget {
  const _BannerImageField({
    required this.image,
    required this.onPick,
    this.onRemove,
  });

  final ImageProvider? image;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final picked = image;
    final radius = BorderRadius.circular(12.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPick,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: 130.h,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: picked == null
                  ? Border.all(color: AppColors.borderDefault)
                  : null,
              color: picked == null
                  ? AppColors.bgCard
                  : AppColors.fgPrimary.withValues(alpha: 0.1),
              image: picked == null
                  ? null
                  : DecorationImage(
                      image: picked,
                      fit: BoxFit.cover,
                      // A dead CDN link or a file the gallery has since removed
                      // must not take the form down — the prompt still shows.
                      onError: (_, __) {},
                    ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (picked != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: const Color(0x4D000000),
                    ),
                    child: const SizedBox.expand(),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      picked != null ? AppIcons.edit : AppIcons.plus,
                      size: 24.sp,
                      color: picked != null
                          ? AppColors.fgOnDark
                          : AppColors.fgTertiary,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      picked != null ? 'Replace image' : 'Upload image · 16:9',
                      style: AppText.figtree(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: picked != null
                            ? AppColors.fgOnDark
                            : AppColors.fgTertiary,
                      ),
                    ),
                  ],
                ),
                if (onRemove != null)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28.r,
                        height: 28.r,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.close,
                          size: 16.sp,
                          color: AppColors.fgOnDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          picked == null
              ? 'Landscape artwork works best — around 1200×675.'
              : 'Tap the image to replace it, or × to remove it.',
          style: AppText.figtree(
            size: 11.5,
            weight: FontWeight.w500,
            color: AppColors.fgTertiary,
          ),
        ),
      ],
    );
  }
}

/// Tappable date cell, matching the coupon form's validity row.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              value.isEmpty ? 'Pick date' : value,
              style: AppText.figtree(
                size: 14,
                weight: FontWeight.w500,
                color: value.isEmpty ? AppColors.fgMuted : AppColors.fgPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
