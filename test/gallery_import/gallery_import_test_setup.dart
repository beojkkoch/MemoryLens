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
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/has_pending_analysis_usecase.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_bloc.dart';
import 'package:memorylens/injection_container.dart';

import '../photo_analysis/fake_photo_analysis_repository.dart';

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
      network = FakeNetworkRepository() {
    // The analysis sees as pending every photo the import registered. The
    // device id stands for the id of the row in foto.
    analysis = FakePhotoAnalysisRepository(importedIds: () => photos.imported);
  }

  /// What the storage and the scan did, in order.
  final List<String> log;
  final FakeDeviceGalleryRepository gallery;
  final FakePhotoImportRepository photos;
  final FakeImportScanRepository scans;
  final FakeNetworkRepository network;
  late final FakePhotoAnalysisRepository analysis;

  /// How long the analysis was asked to wait by the AI, in order.
  final List<Duration> busyWaits = [];
}

/// Registers the fakes and the real use cases of the import and the analysis
/// that follows it. Call it after
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
  sl.registerSingleton<PhotoAnalysisRepository>(fakes.analysis);
  sl.registerLazySingleton(
    () => AnalyzePendingPhotosUseCase(
      wait: (delay) async => fakes.busyWaits.add(delay),
    ),
  );
  sl.registerLazySingleton(() => HasPendingAnalysisUseCase());
  return fakes;
}

/// The Analizando screen with its blocs, as the app provides it. It starts the
/// import at once and does not pause before retrying.
Widget analyzingRoute() {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            GalleryImportBloc(retryDelay: Duration.zero)
              ..add(GalleryImportStarted()),
      ),
      BlocProvider(create: (_) => PhotoAnalysisBloc(retryDelay: Duration.zero)),
    ],
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
