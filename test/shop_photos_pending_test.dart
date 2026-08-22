import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter_project/features/shops/application/pending_shop_photo_upload.dart';

/// The Add Shop form had no way to attach photos at all — they could only be
/// added from the shop's detail strip after the shop existed. The form now
/// collects picks locally and sends them once the create call returns an id.
void main() {
  group('uploadPendingShopPhotos', () {
    test('sends every picked slot to the newly-created shop', () async {
      final sent = <String, String>{};
      final failed = await uploadPendingShopPhotos(
        '42',
        {'cover_image': '/tmp/a.jpg', 'normal_image1': '/tmp/b.jpg'},
        (shopId, {required slot, required filePath}) async {
          expect(shopId, '42');
          sent[slot] = filePath;
        },
      );

      expect(failed, 0);
      expect(sent, {'cover_image': '/tmp/a.jpg', 'normal_image1': '/tmp/b.jpg'});
    });

    test('a failed slot is counted, not thrown — the shop already exists',
        () async {
      final sent = <String>[];
      final failed = await uploadPendingShopPhotos(
        '42',
        {
          'cover_image': '/tmp/a.jpg',
          'normal_image1': '/tmp/bad.jpg',
          'normal_image2': '/tmp/c.jpg',
        },
        (shopId, {required slot, required filePath}) async {
          if (slot == 'normal_image1') throw Exception('413 too large');
          sent.add(slot);
        },
      );

      // The slot after the failure still went out.
      expect(failed, 1);
      expect(sent, ['cover_image', 'normal_image2']);
    });

    test('nothing picked is not an upload', () async {
      var calls = 0;
      final failed = await uploadPendingShopPhotos(
        '42',
        const {},
        (shopId, {required slot, required filePath}) async => calls++,
      );

      expect(failed, 0);
      expect(calls, 0);
    });
  });
}
