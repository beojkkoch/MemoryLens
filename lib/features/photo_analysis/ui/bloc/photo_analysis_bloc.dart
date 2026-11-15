import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_progress.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
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
  final WatchConnectivityUseCase _watch = sl();

  /// Pause between the connection coming back and the next run.
  final Duration _retryDelay;

  PhotoAnalysisBloc({this._retryDelay = const Duration(seconds: 3)})
    : super(const PhotoAnalysisState()) {
    on<PhotoAnalysisStarted>(_onRequested);
    on<PhotoAnalysisRetried>(_onRequested);
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
