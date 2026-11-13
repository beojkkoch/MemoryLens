import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_bloc.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_event.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_state.dart';
import 'package:memorylens/injection_container.dart';

import 'gallery_import_test_setup.dart';

/// Remembers the errors the bloc reports, like the app's observer does.
class _ErrorRecorder extends BlocObserver {
  final errors = <Object>[];

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  const noConnection = AppException(
    'No pudimos conectarnos.',
    kind: AppErrorKind.network,
  );

  late GalleryImportFakes fakes;
  late GalleryImportBloc bloc;
  late _ErrorRecorder recorder;

  setUp(() async {
    await sl.reset();
    fakes = registerGalleryImportFakes();
    recorder = _ErrorRecorder();
    final previousObserver = Bloc.observer;
    Bloc.observer = recorder;
    bloc = GalleryImportBloc(retryDelay: Duration.zero);
    addTearDown(() => Bloc.observer = previousObserver);
    addTearDown(bloc.close);
  });

  /// Completes when the bloc is in [status], now or later.
  Future<GalleryImportState> until(GalleryImportStatus status) {
    if (bloc.state.status == status) return Future.value(bloc.state);
    return bloc.stream
        .firstWhere((state) => state.status == status)
        .timeout(const Duration(seconds: 5));
  }

  test('starts without having done anything', () {
    expect(bloc.state.status, GalleryImportStatus.idle);
    expect(bloc.state.total, 0);
  });

  test('imports the photos and completes', () async {
    fakes.gallery.photos = devicePhotos(5);

    bloc.add(GalleryImportStarted());
    final state = await until(GalleryImportStatus.completed);

    expect(state.total, 5);
    expect(state.imported, 5);
    expect(state.skipped, 0);
    expect(fakes.scans.finished, ['scan-1']);
  });

  test('is importing while it works', () async {
    fakes.gallery.photos = devicePhotos(5);
    final statuses = <GalleryImportStatus>[];
    final subscription = bloc.stream.listen((s) => statuses.add(s.status));
    addTearDown(subscription.cancel);

    bloc.add(GalleryImportStarted());
    await until(GalleryImportStatus.completed);

    expect(statuses.first, GalleryImportStatus.importing);
    expect(statuses.last, GalleryImportStatus.completed);
  });

  test('counts the photos it could not read', () async {
    fakes.gallery.photos = devicePhotos(4);
    fakes.gallery.unreadable.add('p2');

    bloc.add(GalleryImportStarted());
    final state = await until(GalleryImportStatus.completed);

    expect(state.imported, 3);
    expect(state.skipped, 1);
  });

  group('connection', () {
    test('waits while offline and goes on when it is back (CA4)', () async {
      fakes.gallery.photos = devicePhotos(4);
      fakes.photos.uploadErrors['p3'] = noConnection;
      fakes.network.online = false;

      bloc.add(GalleryImportStarted());
      final waiting = await until(GalleryImportStatus.waitingConnection);

      // The photos before the drop are already in.
      expect(waiting.imported, 3);

      // Still waiting: it does not try again while there is no connection.
      await pumpEventQueue();
      expect(bloc.state.status, GalleryImportStatus.waitingConnection);
      expect(fakes.photos.uploadCounts['p3'], 1);

      fakes.photos.uploadErrors.clear();
      fakes.network.setOnline(true);
      final done = await until(GalleryImportStatus.completed);

      expect(done.imported, 4);
      expect(fakes.photos.uploadCounts['p0'], 1);
      expect(fakes.photos.uploadCounts['p3'], 2);
      expect(fakes.scans.finished, ['scan-1']);
    });

    test('a dropped connection is not reported as an error', () async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.photos.uploadErrors['p1'] = noConnection;
      fakes.network.online = false;

      bloc.add(GalleryImportStarted());
      await until(GalleryImportStatus.waitingConnection);

      expect(recorder.errors, isEmpty);
    });

    test('gives up when going online does not fix it', () async {
      fakes.gallery.photos = devicePhotos(1);
      fakes.photos.uploadErrors['p0'] = noConnection;

      bloc.add(GalleryImportStarted());
      final state = await until(GalleryImportStatus.failure);

      expect(
        fakes.photos.uploadCounts['p0'],
        GalleryImportBloc.maxAttemptsWithoutProgress,
      );
      expect(state.errorMessage, noConnection.message);
      expect(recorder.errors, hasLength(1));
    });

    test('closing the bloc while it waits does not try again', () async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.photos.uploadErrors['p1'] = noConnection;
      fakes.network.online = false;

      bloc.add(GalleryImportStarted());
      await until(GalleryImportStatus.waitingConnection);
      await pumpEventQueue();
      await bloc.close().timeout(const Duration(seconds: 5));

      fakes.photos.uploadErrors.clear();
      fakes.network.setOnline(true);
      await pumpEventQueue();

      expect(fakes.photos.uploadCounts['p1'], 1);
    });
  });

  group('failures', () {
    test('another failure stops the import and is reported', () async {
      fakes.gallery.photos = devicePhotos(3);
      fakes.photos.uploadErrors['p1'] = const AppException(
        'Tuvimos un problema de nuestro lado.',
        kind: AppErrorKind.server,
      );

      bloc.add(GalleryImportStarted());
      final state = await until(GalleryImportStatus.failure);

      expect(state.errorMessage, 'Tuvimos un problema de nuestro lado.');
      expect(recorder.errors, hasLength(1));
      expect(fakes.scans.finished, isEmpty);
    });

    test('an unexpected error shows the generic message', () async {
      fakes.gallery.listError = StateError('PlatformException(secret)');

      bloc.add(GalleryImportStarted());
      final state = await until(GalleryImportStatus.failure);

      expect(state.errorMessage, AppException.genericMessage);
      expect(state.errorMessage, isNot(contains('secret')));
    });

    test('«Reintentar» runs the import again and completes', () async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.gallery.listError = const AppException('Sin acceso a tus fotos.');

      bloc.add(GalleryImportStarted());
      await until(GalleryImportStatus.failure);

      fakes.gallery.listError = null;
      bloc.add(GalleryImportRetried());
      final state = await until(GalleryImportStatus.completed);

      expect(state.imported, 2);
      // The old message does not stay on a screen that worked.
      expect(state.errorMessage, isNull);
    });
  });

  group('one import at a time', () {
    test('a second start while importing does not upload twice', () async {
      fakes.gallery.photos = devicePhotos(5);

      bloc
        ..add(GalleryImportStarted())
        ..add(GalleryImportStarted())
        ..add(GalleryImportRetried());
      await until(GalleryImportStatus.completed);
      await pumpEventQueue();

      expect(fakes.photos.uploadCounts.values, everyElement(1));
      expect(fakes.scans.finished, ['scan-1']);
    });

    test('starting again after it completed does nothing', () async {
      fakes.gallery.photos = devicePhotos(2);
      bloc.add(GalleryImportStarted());
      await until(GalleryImportStatus.completed);
      final callsBefore = fakes.log.length;

      bloc.add(GalleryImportRetried());
      await pumpEventQueue();

      expect(fakes.log, hasLength(callsBefore));
    });
  });
}
