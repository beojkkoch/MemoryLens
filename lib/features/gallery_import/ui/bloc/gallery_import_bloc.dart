import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_import/domain/entities/import_progress.dart';
import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_event.dart';
import 'package:memorylens/features/gallery_import/ui/bloc/gallery_import_state.dart';
import 'package:memorylens/injection_container.dart';

/// Runs the import of the gallery and keeps it going through connection drops.
///
/// When the connection fails it waits until the device is back online and runs
/// the import again. That is safe because the import only takes the photos
/// still missing, so it goes on from where it stopped.
class GalleryImportBloc extends Bloc<GalleryImportEvent, GalleryImportState> {
  /// Failed runs in a row, with no new photo imported, before giving up. The
  /// device can say it is online while the internet does not work, so waiting
  /// for the connection alone could loop forever.
  static const maxAttemptsWithoutProgress = 5;

  final ImportGalleryPhotosUseCase _import = sl();
  final WatchConnectivityUseCase _watch = sl();

  /// Pause between the connection coming back and the next run.
  final Duration _retryDelay;

  GalleryImportBloc({this._retryDelay = const Duration(seconds: 3)})
    : super(const GalleryImportState()) {
    on<GalleryImportStarted>(_onRequested);
    on<GalleryImportRetried>(_onRequested);
  }

  Future<void> _onRequested(
    GalleryImportEvent event,
    Emitter<GalleryImportState> emit,
  ) async {
    // Handlers run side by side, so a second event must not start a second
    // import. The check and the emit happen before the first await.
    if (state.status == GalleryImportStatus.importing ||
        state.status == GalleryImportStatus.waitingConnection ||
        state.status == GalleryImportStatus.completed) {
      return;
    }
    emit(state.copyWith(status: GalleryImportStatus.importing));

    var attemptsWithoutProgress = 0;
    while (!emit.isDone) {
      final importedBefore = state.imported;
      try {
        await emit.forEach<ImportProgress>(
          _import(),
          onData: (progress) => state.copyWith(
            status: GalleryImportStatus.importing,
            total: progress.total,
            imported: progress.imported,
            skipped: progress.skipped,
          ),
        );
        if (emit.isDone) return;
        emit(state.copyWith(status: GalleryImportStatus.completed));
        return;
      } catch (e, stack) {
        if (emit.isDone) return;
        if (!_isConnectionProblem(e)) {
          addError(e, stack);
          emit(_failed(e));
          return;
        }

        attemptsWithoutProgress = state.imported > importedBefore
            ? 0
            : attemptsWithoutProgress + 1;
        if (attemptsWithoutProgress >= maxAttemptsWithoutProgress) {
          addError(e, stack);
          emit(_failed(e));
          return;
        }

        // A dropped connection is expected, so it is not reported as an error.
        emit(state.copyWith(status: GalleryImportStatus.waitingConnection));
        await emit.forEach<bool>(
          _watch().where((online) => online).take(1),
          onData: (_) => state,
        );
        // Closing the bloc also ends the wait above: do not go on after that.
        if (emit.isDone) return;
        await Future<void>.delayed(_retryDelay);
        if (emit.isDone) return;
        emit(state.copyWith(status: GalleryImportStatus.importing));
      }
    }
  }

  GalleryImportState _failed(Object error) {
    return state.copyWith(
      status: GalleryImportStatus.failure,
      errorMessage: AppException.messageFor(error),
    );
  }

  bool _isConnectionProblem(Object error) {
    return error is AppException &&
        (error.kind == AppErrorKind.network ||
            error.kind == AppErrorKind.timeout);
  }
}
