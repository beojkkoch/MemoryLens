import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/import_progress.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'gallery_import_test_setup.dart';

void main() {
  late GalleryImportFakes fakes;
  late ImportGalleryPhotosUseCase importPhotos;

  setUp(() async {
    await sl.reset();
    fakes = registerGalleryImportFakes();
    importPhotos = ImportGalleryPhotosUseCase();
  });

  Future<List<ImportProgress>> run() => importPhotos().toList();

  test('uploads every photo of the device and finishes the scan', () async {
    fakes.gallery.photos = devicePhotos(5);

    final progress = await run();

    expect(fakes.photos.imported, {'p0', 'p1', 'p2', 'p3', 'p4'});
    expect(progress.last.total, 5);
    expect(progress.last.imported, 5);
    expect(progress.last.skipped, 0);
    expect(fakes.scans.finished, ['scan-1']);
  });

  test('records the capture date of each photo (CA1)', () async {
    fakes.gallery.photos = devicePhotos(2);

    await run();

    expect(fakes.photos.registered.map((photo) => photo.takenAt), [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
    ]);
  });

  test('a photo with no date is recorded without a date', () async {
    fakes.gallery.photos = [const DeviceGalleryPhoto(assetId: 'x')];

    await run();

    expect(fakes.photos.registered.single.takenAt, isNull);
  });

  test('does not upload again the photos already imported (CA3)', () async {
    fakes.gallery.photos = devicePhotos(5);
    fakes.photos.imported.addAll({'p0', 'p1'});

    final progress = await run();

    expect(fakes.photos.uploadCounts.keys, {'p2', 'p3', 'p4'});
    expect(progress.first.imported, 2);
    expect(progress.last.imported, 5);
  });

  test('saves the total before the first upload (CA5)', () async {
    fakes.gallery.photos = devicePhotos(4);

    await run();

    final totalSaved = fakes.log.indexOf('scan:total=4');
    final firstUpload = fakes.log.indexWhere((e) => e.startsWith('upload:'));
    expect(totalSaved, isNonNegative);
    expect(totalSaved, lessThan(firstUpload));
  });

  test(
    'the saved total counts the whole gallery, not only the new ones',
    () async {
      fakes.gallery.photos = devicePhotos(5);
      fakes.photos.imported.add('p0');

      await run();

      expect(fakes.scans.savedTotal, 5);
    },
  );

  test(
    'goes on from where it stopped after the connection drops (CA4)',
    () async {
      fakes.gallery.photos = devicePhotos(6);
      fakes.photos.uploadErrors['p3'] = const AppException(
        'Sin conexión',
        kind: AppErrorKind.network,
      );

      final progress = <ImportProgress>[];
      await expectLater(
        importPhotos().forEach(progress.add),
        throwsA(isA<AppException>()),
      );

      // The batch that failed still reports the photos that did make it.
      expect(progress.last.imported, 5);
      expect(fakes.scans.finished, isEmpty);
      expect(fakes.scans.pending, isTrue);

      // The connection is back: only the photo that failed is left.
      fakes.photos.uploadErrors.clear();
      final second = await run();

      expect(second.first.imported, 5);
      expect(second.last.imported, 6);
      expect(fakes.photos.uploadCounts['p0'], 1);
      expect(fakes.photos.uploadCounts['p3'], 2);
      expect(fakes.scans.finished, ['scan-1']);
    },
  );

  test('uploads the files before recording the photo', () async {
    fakes.gallery.photos = devicePhotos(4);

    await run();

    for (final photo in fakes.gallery.photos) {
      final uploaded = fakes.log.indexOf('upload:${photo.assetId}');
      final recorded = fakes.log.indexOf('register:${photo.assetId}');
      expect(uploaded, isNonNegative);
      expect(uploaded, lessThan(recorded));
    }
  });

  test('a photo that fails to upload is never recorded as imported', () async {
    fakes.gallery.photos = devicePhotos(2);
    fakes.photos.uploadErrors['p1'] = const AppException('boom');

    await expectLater(run(), throwsA(isA<AppException>()));

    expect(fakes.photos.imported, {'p0'});
  });

  test('a photo that cannot be read is skipped and the rest go on', () async {
    fakes.gallery.photos = devicePhotos(5);
    fakes.gallery.unreadable.add('p1');

    final progress = await run();

    expect(fakes.photos.uploadCounts.containsKey('p1'), isFalse);
    expect(progress.last.imported, 4);
    expect(progress.last.skipped, 1);
    // The import does not look pending forever because of one lost photo.
    expect(fakes.scans.finished, ['scan-1']);
  });

  test('ignores imported photos that were deleted from the device', () async {
    fakes.gallery.photos = devicePhotos(3);
    fakes.photos.imported.addAll({'p0', 'gone1', 'gone2'});

    final progress = await run();

    expect(progress.first.imported, 1);
    expect(progress.last.imported, 3);
    expect(progress.last.total, 3);
  });

  test('an empty gallery finishes with a total of zero', () async {
    final progress = await run();

    expect(fakes.scans.savedTotal, 0);
    expect(progress.single.total, 0);
    expect(fakes.scans.finished, ['scan-1']);
  });

  test('reports the progress at the start and after every batch', () async {
    fakes.gallery.photos = devicePhotos(7);

    final progress = await run();

    // 3 photos at a time: 0, then 3, 6 and 7.
    expect(progress.map((p) => p.imported), [0, 3, 6, 7]);
    expect(ImportGalleryPhotosUseCase.batchSize, 3);
  });

  test(
    'a failure reading the device list is thrown and saves nothing',
    () async {
      fakes.gallery.listError = const AppException('Sin acceso');

      await expectLater(run(), throwsA(isA<AppException>()));

      expect(fakes.log, isEmpty);
    },
  );
}
