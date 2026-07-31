import '../domain/entities/field_driver.dart';

/// Sends one side of a document. Mirrors `DriverMutations.uploadDocument`.
typedef UploadSide = Future<void> Function({
  required String filePath,
  required String kind,
  required String side,
  String? name,
});

/// Uploads the documents attached on the Hire form once the worker exists.
///
/// Documents can only be attached to a worker id, and on the Hire form there is
/// no id until the create call returns — so the picked files wait on the entity
/// and are sent here. Returns the number of sides that failed.
///
/// A failure never aborts the run: the worker has already been created by this
/// point, so the remaining photos are still worth attempting and the caller
/// reports what didn't make it.
Future<int> uploadPendingDocuments(
  List<DriverDocument> documents,
  UploadSide upload,
) async {
  var failed = 0;
  for (final doc in documents) {
    for (final (side, path) in doc.pendingUploads) {
      try {
        await upload(
          filePath: path,
          kind: doc.kind ?? 'other',
          side: side,
          name: doc.name,
        );
      } catch (_) {
        failed++;
      }
    }
  }
  return failed;
}
