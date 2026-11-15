import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_busy_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_progress.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Has the AI describe every imported photo still waiting (HU-08).
///
/// It can be run again after any failure: the photos already analyzed are
/// left out, so it goes on from where it stopped and never pays twice for a
/// photo.
class AnalyzePendingPhotosUseCase {
  /// Calls running at the same time, each with up to
  /// PhotoAnalysisRepository.maxPhotosPerCall photos. With 4 photos a call,
  /// 128 photos are 32 calls: about 3 to 4 minutes, well within the 10 of the
  /// story, and few enough requests a minute for the free plan of the AI.
  static const parallelCalls = 2;

  /// Times a call waits and tries again when the AI asks to wait, before
  /// giving up and letting the person retry.
  static const maxBusyRetries = 4;

  static const busyMessage =
      'El servicio de análisis está muy ocupado. Inténtalo de nuevo en unos '
      'minutos.';

  final PhotoAnalysisRepository _analysis = sl();
  final Future<void> Function(Duration) _wait;

  /// [wait] is how the pause asked by the AI is waited, so tests do not have
  /// to wait for real.
  AnalyzePendingPhotosUseCase({Future<void> Function(Duration)? wait})
    : _wait = wait ?? Future<void>.delayed;

  /// Emits the progress at the start and after every round of calls, and ends
  /// when no photo is left waiting. A failure is thrown after emitting the
  /// photos of that round that did make it.
  Stream<AnalysisProgress> call() async* {
    final backlog = await _analysis.backlog();
    final pending = backlog.pendingIds;
    final total = backlog.analyzed + backlog.failed + pending.length;
    var analyzed = backlog.analyzed;
    var failed = backlog.failed;
    yield AnalysisProgress(total: total, analyzed: analyzed, failed: failed);

    const perCall = PhotoAnalysisRepository.maxPhotosPerCall;
    final calls = [
      for (var start = 0; start < pending.length; start += perCall)
        pending.skip(start).take(perCall).toList(),
    ];

    for (var start = 0; start < calls.length; start += parallelCalls) {
      final round = calls.skip(start).take(parallelCalls);
      final outcomes = await Future.wait(round.map(_analyzeCall));

      _Failure? failure;
      for (final outcome in outcomes) {
        switch (outcome) {
          case _Done(:final ids, :final results):
            for (final id in ids) {
              // A photo the server did not answer for is still pending, so a
              // later run picks it up again.
              switch (results[id]) {
                case PhotoAnalysisOutcome.analyzed:
                  analyzed++;
                case PhotoAnalysisOutcome.failed:
                  failed++;
                case null:
                  break;
              }
            }
          case _Failure():
            failure ??= outcome;
        }
      }

      yield AnalysisProgress(total: total, analyzed: analyzed, failed: failed);
      if (failure != null) {
        Error.throwWithStackTrace(failure.error, failure.stack);
      }
    }
  }

  /// Never throws, so no failing call leaves another one of the round running
  /// without anyone listening.
  Future<_Outcome> _analyzeCall(List<String> ids) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return _Done(ids, await _analysis.analyze(ids));
      } on AnalysisBusyException catch (e, stack) {
        if (attempt >= maxBusyRetries) {
          return _Failure(
            AppException(busyMessage, kind: AppErrorKind.server, cause: e),
            stack,
          );
        }
        await _wait(e.retryAfter);
      } catch (e, stack) {
        return _Failure(e, stack);
      }
    }
  }
}

sealed class _Outcome {
  const _Outcome();
}

class _Done extends _Outcome {
  final List<String> ids;
  final Map<String, PhotoAnalysisOutcome> results;

  const _Done(this.ids, this.results);
}

class _Failure extends _Outcome {
  final Object error;
  final StackTrace stack;

  const _Failure(this.error, this.stack);
}
