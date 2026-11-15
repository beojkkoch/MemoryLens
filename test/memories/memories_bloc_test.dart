import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_state.dart';
import 'package:memorylens/injection_container.dart';

import '../gallery_access/fake_gallery_permission_repository.dart';
import '../gallery_import/gallery_import_test_setup.dart';
import 'fake_photo_repository.dart';

void main() {
  late FakeGalleryPermissionRepository permission;
  late FakePhotoRepository photos;
  late GalleryImportFakes importFakes;
  late MemoriesBloc bloc;

  setUp(() async {
    await sl.reset();
    permission = FakeGalleryPermissionRepository();
    photos = FakePhotoRepository();
    sl.registerSingleton<GalleryPermissionRepository>(permission);
    sl.registerSingleton<PhotoRepository>(photos);
    sl.registerLazySingleton(() => RequestGalleryAccessUseCase());
    sl.registerLazySingleton(() => CheckGalleryAccessUseCase());
    sl.registerLazySingleton(() => OpenGallerySettingsUseCase());
    sl.registerLazySingleton(() => CountPhotosUseCase());
    // Recuerdos asks whether an import was left half done.
    importFakes = registerGalleryImportFakes();
    bloc = MemoriesBloc();
  });

  tearDown(() => bloc.close());

  /// Sends the events one by one and lets the bloc finish each of them.
  Future<void> send(List<MemoriesEvent> events) async {
    for (final event in events) {
      bloc.add(event);
      await pumpEventQueue();
    }
  }

  group('loading', () {
    test('starts loading with nothing connected', () {
      expect(bloc.state.status, MemoriesStatus.loading);
      expect(bloc.state.access, GalleryAccess.idle);
    });

    test('a person without photos gets the empty gallery', () async {
      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.ready);
      expect(bloc.state.photoCount, 0);
      expect(bloc.state.hasPhotos, isFalse);
    });

    test('a person with photos does not get the empty gallery', () async {
      photos.photoCount = 12;

      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.ready);
      expect(bloc.state.photoCount, 12);
      expect(bloc.state.hasPhotos, isTrue);
    });

    test('a failed count shows the reason and can be retried', () async {
      photos.error = const AppException('No pudimos conectarnos.');

      await send([MemoriesStarted()]);
      expect(bloc.state.status, MemoriesStatus.failure);
      expect(bloc.state.errorMessage, 'No pudimos conectarnos.');

      photos.error = null;
      await send([MemoriesStarted()]);
      expect(bloc.state.status, MemoriesStatus.ready);
      expect(bloc.state.errorMessage, isNull);
    });

    test('an unexpected count error shows the generic message', () async {
      photos.error = StateError('Bad state: secret detail');

      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.failure);
      expect(bloc.state.errorMessage, AppException.genericMessage);
    });
  });

  group('an import left half done', () {
    test('goes on to Analizando while the permission is still on', () async {
      photos.photoCount = 3;
      importFakes.scans.pending = true;
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.ready);
      expect(bloc.state.access, GalleryAccess.granted);
    });

    test('does not move on when the person took the permission away', () async {
      importFakes.scans.pending = true;
      permission.checkResult = GalleryPermissionStatus.blocked;

      await send([MemoriesStarted()]);

      expect(bloc.state.access, GalleryAccess.idle);
    });

    test('an analysis left half done also goes on to Analizando', () async {
      photos.photoCount = 3;
      importFakes.scans.pending = false;
      // Imported, but the AI has not described it yet.
      importFakes.photos.imported.add('p0');
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.access, GalleryAccess.granted);
    });

    test('does not move on when nothing is pending', () async {
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.access, GalleryAccess.idle);
      // Nothing pending, so the device is not even asked.
      expect(permission.checkCalls, 0);
    });

    test('a finished import is not resumed', () async {
      photos.photoCount = 3;
      importFakes.scans.pending = false;
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.access, GalleryAccess.idle);
    });

    test('a failing check does not break Recuerdos', () async {
      importFakes.scans.pendingError = const AppException(
        'No pudimos conectarnos.',
        kind: AppErrorKind.network,
      );
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.ready);
      expect(bloc.state.access, GalleryAccess.idle);
      expect(bloc.state.errorMessage, isNull);
    });

    test('is not looked for when the count already failed', () async {
      photos.error = const AppException('No pudimos conectarnos.');
      importFakes.scans.pending = true;
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesStarted()]);

      expect(bloc.state.status, MemoriesStatus.failure);
      expect(bloc.state.access, GalleryAccess.idle);
    });
  });

  group('connecting the gallery', () {
    setUp(() async {
      await send([MemoriesStarted()]);
    });

    test(
      'the button only opens the own dialog, the device is not asked',
      () async {
        await send([GalleryAccessTapped()]);

        expect(bloc.state.access, GalleryAccess.consent);
        expect(permission.requestCalls, 0);
      },
    );

    test(
      '«No permitir» goes back to the empty gallery and never asks',
      () async {
        await send([GalleryAccessTapped(), GalleryConsentDeclined()]);

        expect(bloc.state.access, GalleryAccess.idle);
        expect(bloc.state.status, MemoriesStatus.ready);
        expect(permission.requestCalls, 0);
      },
    );

    test('after «No permitir» the button can try again', () async {
      await send([
        GalleryAccessTapped(),
        GalleryConsentDeclined(),
        GalleryAccessTapped(),
      ]);

      expect(bloc.state.access, GalleryAccess.consent);
      expect(permission.requestCalls, 0);
    });

    test('«Permitir» asks the device and moves on when it says yes', () async {
      permission.requestResult = GalleryPermissionStatus.granted;

      await send([GalleryAccessTapped(), GalleryConsentAccepted()]);

      expect(bloc.state.access, GalleryAccess.granted);
      expect(permission.requestCalls, 1);
    });

    test('a device that says no leaves the person able to try again', () async {
      permission.requestResult = GalleryPermissionStatus.denied;

      await send([GalleryAccessTapped(), GalleryConsentAccepted()]);

      expect(bloc.state.access, GalleryAccess.denied);

      await send([GalleryAccessTapped()]);
      expect(bloc.state.access, GalleryAccess.consent);
    });

    test('a device that blocks the permission is told apart', () async {
      permission.requestResult = GalleryPermissionStatus.blocked;

      await send([GalleryAccessTapped(), GalleryConsentAccepted()]);

      expect(bloc.state.access, GalleryAccess.blocked);
    });

    test('a failing plugin shows a friendly message, not a crash', () async {
      permission.error = StateError('PlatformException(secret)');

      await send([GalleryAccessTapped(), GalleryConsentAccepted()]);

      expect(bloc.state.access, GalleryAccess.idle);
      expect(bloc.state.errorMessage, AppException.genericMessage);
    });
  });

  group('new photos of the device (HU-11)', () {
    /// A person who already imported and analyzed p0 and p1, and has
    /// [onDevice] photos on the device now.
    void connectedWith({required int onDevice}) {
      photos.photoCount = 2;
      permission.checkResult = GalleryPermissionStatus.granted;
      importFakes.gallery.photos = devicePhotos(onDevice);
      importFakes.photos.imported.addAll({'p0', 'p1'});
      importFakes.analysis.done['p0'] = PhotoAnalysisOutcome.analyzed;
      importFakes.analysis.done['p1'] = PhotoAnalysisOutcome.analyzed;
    }

    Future<MemoriesState> until(bool Function(MemoriesState) test) {
      if (test(bloc.state)) return Future.value(bloc.state);
      return bloc.stream.firstWhere(test).timeout(const Duration(seconds: 5));
    }

    test('opening the app imports and analyzes only the new ones '
        '(CA1, CA2, CA3)', () async {
      connectedWith(onDevice: 5);

      bloc.add(MemoriesStarted());
      final working = await until((s) => s.newPhotos > 0);
      expect(working.newPhotos, 3);
      final state = await until((s) => s.newPhotosAnalyzed > 0);

      expect(state.newPhotosAnalyzed, 3);
      expect(state.newPhotos, 0);
      expect(importFakes.photos.imported, {'p0', 'p1', 'p2', 'p3', 'p4'});
      // The photos already processed are not sent again.
      expect(importFakes.analysis.calls.expand((c) => c).toSet(), {
        'p2',
        'p3',
        'p4',
      });
      expect(importFakes.photos.uploadCounts.keys.toSet(), {'p2', 'p3', 'p4'});
      // It stays in Recuerdos: no Analizando in between.
      expect(state.access, GalleryAccess.idle);
    });

    test('N counts only the photos really analyzed', () async {
      connectedWith(onDevice: 4);
      importFakes.analysis.blocked.add('p3');

      bloc.add(MemoriesStarted());
      final state = await until((s) => s.newPhotosAnalyzed > 0);

      expect(state.newPhotosAnalyzed, 1);
    });

    test('without new photos there is no notice (CA4)', () async {
      connectedWith(onDevice: 2);

      await send([MemoriesStarted()]);
      await pumpEventQueue();

      expect(importFakes.gallery.listCalls, 1);
      expect(bloc.state.newPhotos, 0);
      expect(bloc.state.newPhotosAnalyzed, 0);
      expect(importFakes.analysis.calls, isEmpty);
      expect(importFakes.photos.uploadCounts, isEmpty);
    });

    test(
      'a permission taken away in the system stops the search (CA5)',
      () async {
        connectedWith(onDevice: 5);
        permission.checkResult = GalleryPermissionStatus.blocked;

        await send([MemoriesStarted()]);
        await pumpEventQueue();

        expect(importFakes.gallery.listCalls, 0);
        expect(importFakes.photos.uploadCounts, isEmpty);
        expect(bloc.state.newPhotosAnalyzed, 0);
        // Recuerdos does not ask for it again by itself.
        expect(permission.requestCalls, 0);
      },
    );

    test('a person who never connected the gallery is not searched', () async {
      permission.checkResult = GalleryPermissionStatus.granted;
      importFakes.gallery.photos = devicePhotos(3);

      await send([MemoriesStarted()]);

      expect(importFakes.gallery.listCalls, 0);
    });

    test('a lost connection leaves Recuerdos as it was and the next opening '
        'goes on', () async {
      connectedWith(onDevice: 4);
      importFakes.photos.uploadErrors['p3'] = const AppException(
        'No pudimos conectarnos.',
        kind: AppErrorKind.network,
      );

      bloc.add(MemoriesStarted());
      await until((s) => s.newPhotos > 0);
      final state = await until((s) => s.newPhotos == 0);
      expect(state.newPhotosAnalyzed, 0);
      expect(state.errorMessage, isNull);
      expect(state.status, MemoriesStatus.ready);

      importFakes.photos.uploadErrors.clear();
      bloc.add(MemoriesResumed());
      final next = await until((s) => s.newPhotosAnalyzed > 0);
      expect(next.newPhotosAnalyzed, 2);
    });

    test('coming back to the app looks for new photos again', () async {
      connectedWith(onDevice: 2);
      await send([MemoriesStarted()]);
      await pumpEventQueue();
      expect(bloc.state.newPhotosAnalyzed, 0);

      importFakes.gallery.photos = devicePhotos(3);
      bloc.add(MemoriesResumed());
      final state = await until((s) => s.newPhotosAnalyzed > 0);

      expect(state.newPhotosAnalyzed, 1);
    });

    test('two openings in a row do not import the same photos twice', () async {
      connectedWith(onDevice: 4);

      bloc
        ..add(MemoriesStarted())
        ..add(MemoriesResumed());
      await until((s) => s.newPhotosAnalyzed > 0);
      await pumpEventQueue();

      expect(importFakes.photos.uploadCounts, {'p2': 1, 'p3': 1});
    });

    test('the notice can be closed', () async {
      connectedWith(onDevice: 3);
      bloc.add(MemoriesStarted());
      await until((s) => s.newPhotosAnalyzed > 0);

      await send([NewPhotosNoticeDismissed()]);

      expect(bloc.state.newPhotosAnalyzed, 0);
    });
  });

  group('settings', () {
    setUp(() async {
      permission.requestResult = GalleryPermissionStatus.blocked;
      await send([
        MemoriesStarted(),
        GalleryAccessTapped(),
        GalleryConsentAccepted(),
      ]);
    });

    test('«Abrir ajustes» opens the settings of the app', () async {
      await send([GallerySettingsRequested()]);

      expect(permission.openSettingsCalls, 1);
      expect(bloc.state.access, GalleryAccess.blocked);
    });

    test('coming back with the permission on moves on', () async {
      permission.checkResult = GalleryPermissionStatus.granted;

      await send([MemoriesResumed()]);

      expect(bloc.state.access, GalleryAccess.granted);
    });

    test('coming back with the permission still off changes nothing', () async {
      permission.checkResult = GalleryPermissionStatus.denied;

      await send([MemoriesResumed()]);

      expect(bloc.state.access, GalleryAccess.blocked);
    });

    test('a failing check on return keeps the blocked message', () async {
      permission.error = StateError('boom');

      await send([MemoriesResumed()]);

      expect(bloc.state.access, GalleryAccess.blocked);
    });
  });

  test(
    'coming back to the app does not check anything when not blocked',
    () async {
      await send([MemoriesStarted(), MemoriesResumed()]);

      expect(permission.checkCalls, 0);
      expect(bloc.state.access, GalleryAccess.idle);
    },
  );
}
