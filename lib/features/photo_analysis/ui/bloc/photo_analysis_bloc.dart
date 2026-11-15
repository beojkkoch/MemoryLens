import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_progress.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/retry_failed_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_event.dart';
import 'package:memorylens/features/photo_analysis/ui/bloc/photo_analysis_state.dart';
import 'package:memorylens/injection_container.dart';

/// Runs the analysis of the imported photos and keeps it going through
/// connection drops, like GalleryImportBloc does with the import.
///
/// Running it again is safe because only the photos still waiting are sent.
class PhotoAnalysisBloc extends Bloc<PhotoAnalysisEvent, PhotoAnalysisState> {
  /// Failed runs in a row, with no new photo analyzed, before giving up.
  static const maxAttemptsWithoutProgress = 5;

  final AnalyzePendingPhotosUseCase _analyze = sl();
  final RetryFailedPhotosUseCase _retryFailed = sl();
  final WatchConnectivityUseCase _watch = sl();

  /// Pause between the connection coming back and the next run.
  final Duration _retryDelay;

  PhotoAnalysisBloc({this._retryDelay = const Duration(seconds: 3)})
    : super(const PhotoAnalysisState()) {
    on<PhotoAnalysisStarted>(_onRequested);
    on<PhotoAnalysisRetried>(_onRequested);
    on<PhotoAnalysisFailedPhotosRetried>(_onFailedPhotosRetried);
  }

  /// HU-10, CA8: once the analysis ended, the photos «No analizada» go back
  /// to the queue and only they are sent again.
  Future<void> _onFailedPhotosRetried(
    PhotoAnalysisFailedPhotosRetried event,
    Emitter<PhotoAnalysisState> emit,
  ) async {
    // Only when nothing runs, and before the first await, like a start.
    if (state.status != PhotoAnalysisStatus.completed &&
        state.status != PhotoAnalysisStatus.failure) {
      return;
    }
    emit(state.copyWith(status: PhotoAnalysisStatus.analyzing));
    try {
      await _retryFailed();
    } catch (e, stack) {
      if (emit.isDone) return;
      addError(e, stack);
      emit(_failed(e));
      return;
    }
    if (emit.isDone) return;
    await _analyzeUntilDone(emit);
  }

  Future<void> _onRequested(
    PhotoAnalysisEvent event,
    Emitter<PhotoAnalysisState> emit,
  ) async {
    // A second event must not start a second analysis. The check and the
    // emit happen before the first await.
    if (state.status == PhotoAnalysisStatus.analyzing ||
        state.status == PhotoAnalysisStatus.waitingConnection ||
        state.status == PhotoAnalysisStatus.completed) {
      return;
    }
    emit(state.copyWith(status: PhotoAnalysisStatus.analyzing));
    await _analyzeUntilDone(emit);
  }

  /// Runs the analysis until no photo is left waiting, going on by itself
  /// after a connection drop. The status is already analyzing.
  Future<void> _analyzeUntilDone(Emitter<PhotoAnalysisState> emit) async {
    var attemptsWithoutProgress = 0;
    while (!emit.isDone) {
      final doneBefore = state.analyzed + state.failed;
      try {
        await emit.forEach<AnalysisProgress>(
          _analyze(),
          onData: (progress) => state.copyWith(
            status: PhotoAnalysisStatus.analyzing,
            total: progress.total,
            analyzed: progress.analyzed,
            failed: progress.failed,
          ),
        );
        if (emit.isDone) return;
        emit(state.copyWith(status: PhotoAnalysisStatus.completed));
        return;
      } catch (e, stack) {
        if (emit.isDone) return;
        if (!_isConnectionProblem(e)) {
          addError(e, stack);
          emit(_failed(e));
          return;
        }

        attemptsWithoutProgress = state.analyzed + state.failed > doneBefore
            ? 0
            : attemptsWithoutProgress + 1;
        if (attemptsWithoutProgress >= maxAttemptsWithoutProgress) {
          addError(e, stack);
          emit(_failed(e));
          return;
        }

        emit(state.copyWith(status: PhotoAnalysisStatus.waitingConnection));
        await emit.forEach<bool>(
          _watch().where((online) => online).take(1),
          onData: (_) => state,
        );
        if (emit.isDone) return;
        await Future<void>.delayed(_retryDelay);
        if (emit.isDone) return;
        emit(state.copyWith(status: PhotoAnalysisStatus.analyzing));
      }
    }
  }

  PhotoAnalysisState _failed(Object error) {
    return state.copyWith(
      status: PhotoAnalysisStatus.failure,
      errorMessage: AppException.messageFor(error),
    );
  }

  bool _isConnectionProblem(Object error) {
    return error is AppException &&
        (error.kind == AppErrorKind.network ||
            error.kind == AppErrorKind.timeout);
  }
}
