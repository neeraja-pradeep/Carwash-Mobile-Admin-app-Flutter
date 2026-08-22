/// Sends one photo slot. Mirrors `ShopPhotoEditor.uploadFile`.
typedef UploadSlot = Future<void> Function(
  String shopId, {
  required String slot,
  required String filePath,
});

/// Uploads the photos picked on the Add Shop form once the shop exists.
///
/// A photo can only be attached to a shop id, and on the Add form there is no
/// id until the create call returns — so the picked files wait on the form and
/// are sent here, the same way the hire-driver form defers its documents.
/// Returns the number of slots that failed.
///
/// A failure never aborts the run: the shop has already been created by this
/// point, so the remaining photos are still worth attempting and the caller
/// reports what didn't make it.
Future<int> uploadPendingShopPhotos(
  String shopId,
  Map<String, String> pathBySlot,
  UploadSlot upload,
) async {
  var failed = 0;
  for (final entry in pathBySlot.entries) {
    try {
      await upload(shopId, slot: entry.key, filePath: entry.value);
    } catch (_) {
      failed++;
    }
  }
  return failed;
}
