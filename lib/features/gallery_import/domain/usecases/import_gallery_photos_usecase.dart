import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/entities/import_progress.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Imports the photos of the device into the person's storage.
///
/// It can be run again after any failure: the photos already imported are
/// found in the storage and left out, so it goes on from where it stopped and
/// never uploads a photo twice. The device is only read.
class ImportGalleryPhotosUseCase {
  /// Photos handled at the same time. Each one is about 1 MB in memory.
  static const batchSize = 3;

  final DeviceGalleryRepository _gallery = sl();
  final PhotoImportRepository _photos = sl();
  final ImportScanRepository _scans = sl();

  /// Emits the progress at the start and after every batch, and ends when the
  /// whole gallery was handled. A network or storage failure is thrown, after
  /// emitting the photos of that batch that did make it.
  Stream<ImportProgress> call() async* {
    final onDevice = await _gallery.listPhotos();
    final stored = await _photos.importedAssetIds();

    // Only the ones still on the device count: the person may have deleted
    // photos that were imported earlier.
    final deviceIds = onDevice.map((photo) => photo.assetId).toSet();
    final alreadyDone = stored.intersection(deviceIds);
    final pending = onDevice
        .where((photo) => !alreadyDone.contains(photo.assetId))
        .toList();

    // The total is saved before the first upload.
    final scan = await _scans.startOrResume(total: onDevice.length);

    var imported = alreadyDone.length;
    var skipped = 0;
    yield ImportProgress(
      total: onDevice.length,
      imported: imported,
      skipped: skipped,
    );

    for (var start = 0; start < pending.length; start += batchSize) {
      final batch = pending.skip(start).take(batchSize);
      final outcomes = await Future.wait(batch.map(_importOne));

      _Failure? failure;
      for (final outcome in outcomes) {
        switch (outcome) {
          case _Imported():
            imported++;
          case _Skipped():
            skipped++;
          case _Failure():
            failure ??= outcome;
        }
      }

      yield ImportProgress(
        total: onDevice.length,
        imported: imported,
        skipped: skipped,
      );
      if (failure != null) {
        Error.throwWithStackTrace(failure.error, failure.stack);
      }
    }

    // Even with skipped photos: they are not retried by themselves, but the
    // import must not look pending forever.
    await _scans.markImportFinished(scan.id);
  }

  /// Never throws, so no failing photo leaves another one of the batch
  /// running without anyone listening.
  Future<_Outcome> _importOne(DeviceGalleryPhoto photo) async {
    try {
      final image = await _gallery.readImage(photo.assetId);
      final thumbnail = await _gallery.readThumbnail(photo.assetId);
      if (image == null || thumbnail == null) return const _Skipped();

      final storedPhoto = await _photos.upload(
        assetId: photo.assetId,
        image: image,
        thumbnail: thumbnail,
      );
      await _photos.register(photo: photo, stored: storedPhoto);
      return const _Imported();
    } catch (e, stack) {
      return _Failure(e, stack);
    }
  }
}

sealed class _Outcome {
  const _Outcome();
}

class _Imported extends _Outcome {
  const _Imported();
}

class _Skipped extends _Outcome {
  const _Skipped();
}

class _Failure extends _Outcome {
  final Object error;
  final StackTrace stack;

  const _Failure(this.error, this.stack);
}
