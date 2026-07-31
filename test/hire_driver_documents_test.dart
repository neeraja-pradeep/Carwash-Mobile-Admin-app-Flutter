import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/drivers/application/pending_document_upload.dart';
import 'package:new_flutter_project/features/drivers/domain/entities/field_driver.dart';

/// Documents added while hiring used to be dropped on save: the form collected
/// them in memory, the hire payload had no document field, and nothing uploaded
/// them afterwards — the admin got a "Document added" toast and lost the file.
/// They must reach the backend once the new worker has an id.
void main() {
  DriverDocument pending({
    String id = 'dc_1',
    String type = 'License',
    String? kind = 'license',
    String? name,
    String? front = '/tmp/front.jpg',
    String? back,
  }) =>
      DriverDocument(
        id: id,
        type: type,
        front: front != null,
        back: back != null,
        kind: kind,
        name: name,
        localFrontPath: front,
        localBackPath: back,
      );

  DriverDocument serverDoc() => const DriverDocument(
        id: '4',
        type: 'Aadhaar',
        front: true,
        back: true,
        kind: 'aadhaar',
        frontFileUrl: 'https://cdn.example.test/a-front.jpg',
        backFileUrl: 'https://cdn.example.test/a-back.jpg',
      );

  /// Records every upload the run attempts.
  ({List<Map<String, String?>> calls, UploadSide upload}) recorder({
    Set<String> failOnSides = const {},
  }) {
    final calls = <Map<String, String?>>[];
    Future<void> upload({
      required String filePath,
      required String kind,
      required String side,
      String? name,
    }) async {
      calls.add({
        'filePath': filePath,
        'kind': kind,
        'side': side,
        'name': name,
      });
      if (failOnSides.contains(side)) throw Exception('upload failed');
    }

    return (calls: calls, upload: upload);
  }

  group('pendingUploads', () {
    test('lists the picked sides, front first', () {
      final doc = pending(front: '/tmp/f.jpg', back: '/tmp/b.jpg');
      expect(doc.pendingUploads, [
        ('front', '/tmp/f.jpg'),
        ('back', '/tmp/b.jpg'),
      ]);
    });

    test('a one-sided document offers only that side', () {
      expect(pending(back: null).pendingUploads, [('front', '/tmp/front.jpg')]);
    });

    test('a document already on the server has nothing pending', () {
      // Edit mode holds server documents; re-saving must not re-upload them.
      expect(serverDoc().pendingUploads, isEmpty);
    });
  });

  group('uploadPendingDocuments', () {
    test('sends every picked side of every document', () async {
      final r = recorder();
      final failed = await uploadPendingDocuments([
        pending(id: 'dc_1', kind: 'license', front: '/tmp/l-f.jpg', back: '/tmp/l-b.jpg'),
        pending(id: 'dc_2', kind: 'aadhaar', front: '/tmp/a-f.jpg'),
      ], r.upload);

      expect(failed, 0);
      expect(r.calls.map((c) => c['filePath']), [
        '/tmp/l-f.jpg',
        '/tmp/l-b.jpg',
        '/tmp/a-f.jpg',
      ]);
      expect(r.calls.map((c) => c['side']), ['front', 'back', 'front']);
      expect(r.calls.map((c) => c['kind']), ['license', 'license', 'aadhaar']);
    });

    test('carries a custom name so "Other" documents keep their title',
        () async {
      final r = recorder();
      await uploadPendingDocuments(
        [pending(type: 'Bank passbook', kind: 'other', name: 'Bank passbook')],
        r.upload,
      );

      expect(r.calls.single['name'], 'Bank passbook');
      expect(r.calls.single['kind'], 'other');
    });

    test('falls back to the other kind when none was resolved', () async {
      final r = recorder();
      await uploadPendingDocuments([pending(kind: null)], r.upload);

      expect(r.calls.single['kind'], 'other');
    });

    test('skips documents that are already on the server', () async {
      final r = recorder();
      final failed = await uploadPendingDocuments(
        [serverDoc(), pending()],
        r.upload,
      );

      expect(failed, 0);
      expect(r.calls, hasLength(1));
      expect(r.calls.single['filePath'], '/tmp/front.jpg');
    });

    test('nothing attached means nothing sent', () async {
      final r = recorder();
      expect(await uploadPendingDocuments([], r.upload), 0);
      expect(r.calls, isEmpty);
    });

    test('one failed side does not abandon the rest', () async {
      // The worker already exists at this point — giving up on the remaining
      // photos would lose them for no reason.
      final r = recorder(failOnSides: {'back'});
      final failed = await uploadPendingDocuments([
        pending(id: 'dc_1', front: '/tmp/l-f.jpg', back: '/tmp/l-b.jpg'),
        pending(id: 'dc_2', front: '/tmp/a-f.jpg'),
      ], r.upload);

      expect(failed, 1);
      expect(r.calls, hasLength(3), reason: 'all three sides were attempted');
    });

    test('counts each failed side so the admin can be told', () async {
      final r = recorder(failOnSides: {'front', 'back'});
      final failed = await uploadPendingDocuments(
        [pending(front: '/tmp/f.jpg', back: '/tmp/b.jpg')],
        r.upload,
      );

      expect(failed, 2);
    });
  });
}
