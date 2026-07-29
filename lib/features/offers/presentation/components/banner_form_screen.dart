import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/entities/offer_banner.dart';
import 'form_helpers.dart';

/// Add / Edit banner form — pushed intra-module via Navigator.
class BannerFormScreen extends StatefulWidget {
  const BannerFormScreen({this.banner, super.key});

  /// Null when creating a new banner.
  final OfferBanner? banner;

  @override
  State<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<BannerFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _orderCtrl;
  late String _placement;
  late bool _active;

  /// Filesystem path of an image picked on this device, or null when the form
  /// is still showing the banner's existing artwork (or nothing at all).
  String? _imagePath;

  /// Set when the admin clears the existing artwork without picking a
  /// replacement — distinguishes "no image yet" from "remove the current one".
  bool _imageCleared = false;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _linkCtrl = TextEditingController(text: b?.link ?? '');
    _orderCtrl = TextEditingController(text: b != null ? '${b.order}' : '1');
    _placement =
        (b != null && b.placement.contains('Strip')) ? 'strip' : 'hero';
    _active = b?.status == 'active';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _linkCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  /// The artwork the preview should show: a freshly picked file wins, then the
  /// banner's existing asset unless it has been cleared.
  ImageProvider? get _previewImage {
    final picked = _imagePath;
    if (picked != null) return FileImage(File(picked));
    if (_imageCleared) return null;
    final existing = widget.banner?.image;
    if (existing == null || existing.trim().isEmpty) return null;
    return AssetImage(existing);
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.banner != null;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(
              title: isEdit ? 'Edit Banner' : 'Add Banner',
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
                          ('hero', 'Home — Hero'),
                          ('strip', 'Home — Strip'),
                        ],
                        onChanged: (v) => setState(() => _placement = v),
                      ),
                      SizedBox(height: 14.h),
                      OfferFInput(
                        label: 'Links to',
                        controller: _linkCtrl,
                        placeholder: 'Coupon, service, or screen',
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
            label: isEdit ? 'Save Changes' : 'Create Banner',
            full: true,
            disabled: !_valid,
            onPressed: _valid
                ? () {
                    AppToast.show(
                      context,
                      isEdit ? 'Banner saved' : 'Banner created',
                    );
                    Navigator.of(context).pop();
                  }
                : null,
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
              border:
                  picked == null ? Border.all(color: AppColors.borderDefault) : null,
              color: picked == null
                  ? AppColors.bgCard
                  : AppColors.fgPrimary.withValues(alpha: 0.1),
              image: picked == null
                  ? null
                  : DecorationImage(
                      image: picked,
                      fit: BoxFit.cover,
                      // A missing asset or a file the gallery has since removed
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
