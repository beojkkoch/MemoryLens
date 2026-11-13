import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/entities/device_gallery_photo.dart';
import 'package:memorylens/features/gallery_import/domain/repository/device_gallery_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/import_scan_repository.dart';
import 'package:memorylens/features/gallery_import/domain/repository/photo_import_repository.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/has_pending_import_usecase.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_bloc.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_event.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_device_gallery_repository.dart';
import 'fake_import_scan_repository.dart';
import 'fake_network_repository.dart';
import 'fake_photo_import_repository.dart';

/// The fakes behind the import, so a test can set them up and look at them.
class GalleryImportFakes {
  GalleryImportFakes._(this.log)
    : gallery = FakeDeviceGalleryRepository(),
      photos = FakePhotoImportRepository(log: log),
      scans = FakeImportScanRepository(log: log),
      network = FakeNetworkRepository();

  /// What the storage and the scan did, in order.
  final List<String> log;
  final FakeDeviceGalleryRepository gallery;
  final FakePhotoImportRepository photos;
  final FakeImportScanRepository scans;
  final FakeNetworkRepository network;
}

/// Registers the fakes and the real use cases of the import. Call it after
/// `sl.reset()`, once per test.
GalleryImportFakes registerGalleryImportFakes() {
  final fakes = GalleryImportFakes._([]);
  sl.registerSingleton<DeviceGalleryRepository>(fakes.gallery);
  sl.registerSingleton<PhotoImportRepository>(fakes.photos);
  sl.registerSingleton<ImportScanRepository>(fakes.scans);
  sl.registerSingleton<ConnectivityRepository>(fakes.network);
  sl.registerLazySingleton(() => ImportGalleryPhotosUseCase());
  sl.registerLazySingleton(() => HasPendingImportUseCase());
  sl.registerLazySingleton(() => WatchConnectivityUseCase());
  return fakes;
}

/// The Analizando screen with its bloc, as the app provides it. It starts the
/// import at once and does not pause before retrying.
Widget analyzingRoute() {
  return BlocProvider(
    create: (_) =>
        GalleryImportBloc(retryDelay: Duration.zero)
          ..add(GalleryImportStarted()),
    child: const AnalyzingScreen(),
  );
}

/// [count] photos of the device, p0 to p(count - 1), each with a date.
List<DeviceGalleryPhoto> devicePhotos(int count) {
  return List.generate(
    count,
    (i) =>
        DeviceGalleryPhoto(assetId: 'p$i', takenAt: DateTime(2026, 1, i + 1)),
  );
}
