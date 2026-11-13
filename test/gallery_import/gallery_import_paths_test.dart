import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/gallery_import/data/source/device_gallery_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_imported_photo_data_source.dart';
import 'package:memorylens/features/gallery_import/data/source/supabase_photo_storage_data_source.dart';

void main() {
  group('storage paths', () {
    // iOS ids hold slashes, Android ones are plain numbers.
    const iosId = 'B84E8479-475C-4727-A4A4-B77AA9980897/L0/001';
    const androidId = '1042';

    test('the same photo always gets the same path', () {
      expect(
        SupabasePhotoStorageDataSource.pathForImage('user', iosId),
        SupabasePhotoStorageDataSource.pathForImage('user', iosId),
      );
    });

    test('an id with slashes does not add folders to the path', () {
      final path = SupabasePhotoStorageDataSource.pathForImage('user', iosId);

      expect(path.split('/'), hasLength(2));
      expect(path, startsWith('user/'));
      expect(path, endsWith('.jpg'));
    });

    test('the thumbnail lives in the thumbs folder of the same person', () {
      final path = SupabasePhotoStorageDataSource.pathForThumbnail(
        'user',
        androidId,
      );

      expect(path.split('/'), ['user', 'thumbs', '${_key(androidId)}.jpg']);
    });

    test('different photos never share a path', () {
      final keys = {
        for (final id in [iosId, androidId, '1043', 'a/b', 'a_b', 'a-b'])
          SupabasePhotoStorageDataSource.keyFor(id),
      };

      expect(keys, hasLength(6));
    });

    test('the key can be turned back into the device id', () {
      final key = SupabasePhotoStorageDataSource.keyFor(iosId);
      final padded = key.padRight((key.length + 3) ~/ 4 * 4, '=');

      expect(utf8.decode(base64Url.decode(padded)), iosId);
    });

    test('the key is safe as a file name', () {
      final key = SupabasePhotoStorageDataSource.keyFor(iosId);

      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });
  });

  group('sizes', () {
    test('a big photo is scaled down keeping its proportion', () {
      final size = DeviceGalleryDataSource.fitSize(4000, 3000, 2560);

      expect(size.width, 2560);
      expect(size.height, 1920);
    });

    test('a tall photo is limited on its height', () {
      final size = DeviceGalleryDataSource.fitSize(3000, 4000, 400);

      expect(size.width, 300);
      expect(size.height, 400);
    });

    test('a small photo is never enlarged', () {
      final size = DeviceGalleryDataSource.fitSize(300, 200, 400);

      expect(size.width, 300);
      expect(size.height, 200);
    });

    test('a photo with unknown size falls back to a square', () {
      final size = DeviceGalleryDataSource.fitSize(0, 0, 400);

      expect(size.width, 400);
      expect(size.height, 400);
    });
  });

  group('capture date', () {
    test('seconds become a date', () {
      expect(
        DeviceGalleryDataSource.takenAtFromSeconds(1767225600),
        DateTime.fromMillisecondsSinceEpoch(1767225600 * 1000),
      );
    });

    test('a missing or zero date is never turned into 1970', () {
      expect(DeviceGalleryDataSource.takenAtFromSeconds(null), isNull);
      expect(DeviceGalleryDataSource.takenAtFromSeconds(0), isNull);
    });
  });

  group('imported ids paging', () {
    const pageSize = SupabaseImportedPhotoDataSource.pageSize;

    /// Serves [total] rows the way the server would, one page at a time.
    Future<List<Map<String, dynamic>>> Function(int, int) server(
      int total,
      List<(int, int)> asked,
    ) {
      return (from, to) async {
        asked.add((from, to));
        return [
          for (var i = from; i <= to && i < total; i++) {'asset_id': 'id$i'},
        ];
      };
    }

    test('reads past the first page so no imported photo looks new', () async {
      final asked = <(int, int)>[];

      final ids = await SupabaseImportedPhotoDataSource.collectAssetIds(
        server(2500, asked),
      );

      expect(ids, hasLength(2500));
      expect(asked, [
        (0, pageSize - 1),
        (pageSize, 2 * pageSize - 1),
        (2 * pageSize, 3 * pageSize - 1),
      ]);
    });

    test(
      'a full last page asks once more and stops on the empty one',
      () async {
        final asked = <(int, int)>[];

        final ids = await SupabaseImportedPhotoDataSource.collectAssetIds(
          server(pageSize, asked),
        );

        expect(ids, hasLength(pageSize));
        expect(asked, hasLength(2));
      },
    );

    test('no imported photos is an empty set after one request', () async {
      final asked = <(int, int)>[];

      final ids = await SupabaseImportedPhotoDataSource.collectAssetIds(
        server(0, asked),
      );

      expect(ids, isEmpty);
      expect(asked, hasLength(1));
    });
  });
}

String _key(String id) => SupabasePhotoStorageDataSource.keyFor(id);
