import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/has_pending_import_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_device_gallery_repository.dart';
import 'fake_import_scan_repository.dart';
import 'fake_photo_import_repository.dart';

/// The fakes behind the import, so a test can set them up and look at them.
class GalleryImportFakes {
  GalleryImportFakes._(this.log)
    : gallery = FakeDeviceGalleryRepository(),
      photos = FakePhotoImportRepository(log: log),
      scans = FakeImportScanRepository(log: log);

  /// What the storage and the scan did, in order.
  final List<String> log;
  final FakeDeviceGalleryRepository gallery;
  final FakePhotoImportRepository photos;
  final FakeImportScanRepository scans;
}

/// Registers the fakes and the real use cases of the import. Call it after
/// `sl.reset()`, once per test.
GalleryImportFakes registerGalleryImportFakes() {
  final fakes = GalleryImportFakes._([]);
  sl.registerSingleton<DeviceGalleryRepository>(fakes.gallery);
  sl.registerSingleton<PhotoImportRepository>(fakes.photos);
  sl.registerSingleton<ImportScanRepository>(fakes.scans);
  sl.registerLazySingleton(() => ImportGalleryPhotosUseCase());
  sl.registerLazySingleton(() => HasPendingImportUseCase());
  return fakes;
}

/// [count] photos of the device, p0 to p(count - 1), each with a date.
List<DeviceGalleryPhoto> devicePhotos(int count) {
  return List.generate(
    count,
    (i) =>
        DeviceGalleryPhoto(assetId: 'p$i', takenAt: DateTime(2026, 1, i + 1)),
  );
}
