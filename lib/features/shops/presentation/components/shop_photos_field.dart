import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:new_flutter_project/app/theme/colors.dart';
import 'package:new_flutter_project/app/theme/typography.dart';
import 'package:new_flutter_project/core/widgets/app_icons.dart';
import 'package:new_flutter_project/core/widgets/app_toast.dart';

import '../../application/providers/shops_providers.dart';
import '../../domain/entities/shop.dart';

/// The five shop photo slots on the Add / Edit Shop form — one cover and four
/// gallery images, in [kShopPhotoSlots] order.
///
/// Add mode ([shopId] null) has nothing to attach a file to yet, so a pick is
/// held as a local path in [pending] and the form uploads it once the create
/// call returns. Edit mode uploads the pick straight away, which is also the
/// only way to reach `normal_image3` / `normal_image4` — the detail screen's
/// strip shows three cells and stops offering "Add" once they are full.
class ShopPhotosField extends ConsumerStatefulWidget {
  const ShopPhotosField({
    required this.shopId,
    required this.photos,
    required this.pending,
    required this.onPendingChanged,
    super.key,
  });

  /// Null while adding — the shop does not exist yet.
  final String? shopId;

  /// Already-uploaded photos, empty while adding.
  final List<ShopPhoto> photos;

  /// Slot → local file path for picks not yet sent. Owned by the form.
  final Map<String, String> pending;

  final ValueChanged<Map<String, String>> onPendingChanged;

  @override
  ConsumerState<ShopPhotosField> createState() => _ShopPhotosFieldState();
}

class _ShopPhotosFieldState extends ConsumerState<ShopPhotosField> {
  /// The slot currently uploading (edit mode) — shows a spinner and blocks
  /// further picks so two PATCHes can't race on the same shop.
  String? _uploadingSlot;

  String? _remoteUrl(String slot) {
    for (final photo in widget.photos) {
      if (photo.slot == slot && photo.url.isNotEmpty) return photo.url;
    }
    return null;
  }

  Future<void> _pick(String slot) async {
    if (_uploadingSlot != null) return;

    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not open gallery');
      return;
    }
    if (file == null || !mounted) return;

    final shopId = widget.shopId;
    if (shopId == null) {
      widget.onPendingChanged({...widget.pending, slot: file.path});
      return;
    }

    setState(() => _uploadingSlot = slot);
    try {
      await ref.read(shopPhotoEditorProvider).uploadFile(
            shopId,
            slot: slot,
            filePath: file.path,
          );
      if (mounted) AppToast.show(context, 'Photo updated');
    } catch (e) {
      if (mounted) {
        AppToast.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploadingSlot = null);
    }
  }

  /// Drops a pick that has not been sent yet. An uploaded photo stays — the
  /// API has no way to clear a slot, only to replace what is in it.
  void _clear(String slot) {
    final next = {...widget.pending}..remove(slot);
    widget.onPendingChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Slot(
          slot: kShopPhotoSlots.first,
          label: 'COVER',
          height: 132.h,
          localPath: widget.pending[kShopPhotoSlots.first],
          remoteUrl: _remoteUrl(kShopPhotoSlots.first),
          uploading: _uploadingSlot == kShopPhotoSlots.first,
          onTap: () => _pick(kShopPhotoSlots.first),
          onClear: () => _clear(kShopPhotoSlots.first),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            for (final slot in kShopPhotoSlots.skip(1)) ...[
              Expanded(
                child: _Slot(
                  slot: slot,
                  height: 68.h,
                  localPath: widget.pending[slot],
                  remoteUrl: _remoteUrl(slot),
                  uploading: _uploadingSlot == slot,
                  onTap: () => _pick(slot),
                  onClear: () => _clear(slot),
                ),
              ),
              if (slot != kShopPhotoSlots.last) SizedBox(width: 8.w),
            ],
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          widget.shopId == null
              ? 'Optional — uploaded right after the shop is created.'
              : 'Tap a photo to replace it.',
          style: AppText.figtree(
            size: 11.5,
            weight: FontWeight.w400,
            color: AppColors.fgMuted,
          ),
        ),
      ],
    );
  }
}

/// One photo cell: the picked file, the uploaded photo, or an empty "Add" box.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.height,
    required this.localPath,
    required this.remoteUrl,
    required this.uploading,
    required this.onTap,
    required this.onClear,
    this.label,
  });

  final String slot;
  final double height;
  final String? localPath;
  final String? remoteUrl;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    final hasImage = localPath != null || remoteUrl != null;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasImage ? AppColors.borderSoft : AppColors.bgCard,
          borderRadius: radius,
          border: Border.all(color: AppColors.borderDefault),
          image: hasImage
              ? DecorationImage(
                  image: localPath != null
                      ? FileImage(File(localPath!)) as ImageProvider
                      : NetworkImage(remoteUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
        ),
        child: Stack(
          children: [
            if (!hasImage)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.plus,
                        size: 18.sp, color: AppColors.fgTertiary),
                    if (label != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        label!,
                        style: AppText.figtree(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.fgTertiary,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (hasImage && label != null)
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: EdgeInsets.all(7.r),
                  padding:
                      EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    label!,
                    style: AppText.figtree(
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
              ),
            // Only a pick can be taken back — an uploaded slot is replaced,
            // never emptied.
            if (localPath != null && !uploading)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    margin: EdgeInsets.all(6.r),
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.close,
                        size: 13.sp, color: Colors.white),
                  ),
                ),
              ),
            if (uploading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: radius,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
