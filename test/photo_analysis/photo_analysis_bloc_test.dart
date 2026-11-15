import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_bloc.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_event.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_state.dart';
import 'package:memorylens/injection_container.dart';

import '../gallery_import/gallery_import_test_setup.dart';

void main() {
  const noConnection = AppException(
    'No pudimos conectarnos.',
    kind: AppErrorKind.network,
  );

  late GalleryImportFakes fakes;
  late PhotoAnalysisBloc bloc;

  setUp(() async {
    await sl.reset();
    fakes = registerGalleryImportFakes();
    bloc = PhotoAnalysisBloc(retryDelay: Duration.zero);
    addTearDown(bloc.close);
  });

  /// Completes when the bloc is in [status], now or later.
  Future<PhotoAnalysisState> until(PhotoAnalysisStatus status) {
    if (bloc.state.status == status) return Future.value(bloc.state);
    return bloc.stream
        .firstWhere((state) => state.status == status)
        .timeout(const Duration(seconds: 5));
  }

  void imported(int count) {
    fakes.photos.imported.addAll(List.generate(count, (i) => 'p$i'));
  }

  test('waits for the import before doing anything', () {
    expect(bloc.state.status, PhotoAnalysisStatus.idle);
  });

  test('analyzes the imported photos and completes', () async {
    imported(6);

    bloc.add(PhotoAnalysisStarted());
    final state = await until(PhotoAnalysisStatus.completed);

    expect(state.total, 6);
    expect(state.analyzed, 6);
    expect(state.failed, 0);
  });

  test('counts the photos the AI could not describe', () async {
    imported(3);
    fakes.analysis.blocked.add('p1');

    bloc.add(PhotoAnalysisStarted());
    final state = await until(PhotoAnalysisStatus.completed);

    expect(state.analyzed, 2);
    expect(state.failed, 1);
  });

  test(
    'a second start while it works does not start another analysis',
    () async {
      imported(2);

      bloc
        ..add(PhotoAnalysisStarted())
        ..add(PhotoAnalysisStarted());
      await until(PhotoAnalysisStatus.completed);

      expect(fakes.analysis.calls, hasLength(1));
    },
  );

  test('waits for the connection and goes on by itself', () async {
    imported(2);
    fakes.analysis.nextErrors.add(noConnection);
    fakes.network.online = false;

    bloc.add(PhotoAnalysisStarted());
    await until(PhotoAnalysisStatus.waitingConnection);

    fakes.network.setOnline(true);
    final state = await until(PhotoAnalysisStatus.completed);

    expect(state.analyzed, 2);
  });

  test('another failure shows its message and «Reintentar» recovers', () async {
    imported(2);
    fakes.analysis.backlogError = const AppException(
      'Tuvimos un problema de nuestro lado.',
      kind: AppErrorKind.server,
    );

    bloc.add(PhotoAnalysisStarted());
    final failed = await until(PhotoAnalysisStatus.failure);
    expect(failed.errorMessage, 'Tuvimos un problema de nuestro lado.');

    fakes.analysis.backlogError = null;
    bloc.add(PhotoAnalysisRetried());
    final state = await until(PhotoAnalysisStatus.completed);

    expect(state.analyzed, 2);
    expect(state.errorMessage, isNull);
  });
}
