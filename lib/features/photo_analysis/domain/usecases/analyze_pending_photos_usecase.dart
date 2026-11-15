import 'dart:async';
import 'dart:collection';

import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_busy_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_progress.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Has the AI describe every imported photo still waiting (HU-08) and keeps
/// the count of how far it got (HU-10).
///
/// It can be run again after any failure: the photos already analyzed are
/// left out, so it goes on from where it stopped and never pays twice for a
/// photo.
///
/// A failure that has to do with one photo or one call does not stop the
/// rest: the photo is tried again, up to [maxAttempts] times, and then marked
/// as «No analizada». Only a lost connection or an AI that stays busy stops
/// the run, since every other photo would fail the same way.
class AnalyzePendingPhotosUseCase {
  /// Calls running at the same time, each with up to
  /// PhotoAnalysisRepository.maxPhotosPerCall photos. With 4 photos a call,
  /// 128 photos are 32 calls: about 3 to 4 minutes, well within the 10 of the
  /// story, and few enough requests a minute for the free plan of the AI.
  static const parallelCalls = 2;

  /// Attempts of a photo before it is «No analizada» (HU-10, CA6).
  static const maxAttempts = 3;

  /// Pause before trying a call again after it failed.
  static const retryPause = Duration(seconds: 2);

  /// Times a call waits and tries again when the AI asks to wait, before
  /// giving up and letting the person retry. Waiting is not an attempt: it is
  /// not the fault of the photo.
  static const maxBusyRetries = 4;

  static const busyMessage =
      'El servicio de análisis está muy ocupado. Inténtalo de nuevo en unos '
      'minutos.';

  final PhotoAnalysisRepository _analysis = sl();
  final Future<void> Function(Duration) _wait;

  /// [wait] is how the pauses are waited, so tests do not have to wait for
  /// real.
  AnalyzePendingPhotosUseCase({Future<void> Function(Duration)? wait})
    : _wait = wait ?? Future<void>.delayed;

  /// Emits the real progress at the start and every time a call ends, and
  /// ends when no photo is left waiting. A lost connection or an AI that
  /// stays busy is thrown once the calls already running are over.
  Stream<AnalysisProgress> call() {
    var cancelled = false;
    late final StreamController<AnalysisProgress> controller;
    controller = StreamController<AnalysisProgress>(
      onListen: () async {
        try {
          await _run(controller.add, () => cancelled);
        } catch (e, stack) {
          if (!cancelled) controller.addError(e, stack);
        } finally {
          if (!cancelled) await controller.close();
        }
      },
      // Returns nothing on purpose: the calls already running finish, but no
      // new one starts.
      onCancel: () {
        cancelled = true;
      },
    );
    return controller.stream;
  }

  Future<void> _run(
    void Function(AnalysisProgress) emit,
    bool Function() cancelled,
  ) async {
    final backlog = await _analysis.backlog();
    final total = backlog.analyzed + backlog.failed + backlog.pendingIds.length;
    var analyzed = backlog.analyzed;
    var failed = backlog.failed;
    void report() => emit(
      AnalysisProgress(total: total, analyzed: analyzed, failed: failed),
    );
    report();

    final queue = Queue<String>.of(backlog.pendingIds);
    // Times each photo went back to the queue in this run. The server keeps
    // the real count; this only makes sure a run always ends.
    final requeued = <String, int>{};
    _Stop? stop;

    Future<void> worker() async {
      while (queue.isNotEmpty && stop == null && !cancelled()) {
        final ids = <String>[];
        while (ids.length < PhotoAnalysisRepository.maxPhotosPerCall &&
            queue.isNotEmpty) {
          ids.add(queue.removeFirst());
        }

        final outcome = await _analyzeCall(ids);
        switch (outcome) {
          case _Done(:final results):
            for (final id in ids) {
              switch (results[id]) {
                case PhotoAnalysisOutcome.analyzed:
                  analyzed++;
                case PhotoAnalysisOutcome.failed:
                  failed++;
                case PhotoAnalysisOutcome.retry:
                  final times = requeued[id] = (requeued[id] ?? 0) + 1;
                  if (times < maxAttempts) queue.addLast(id);
                case null:
                  // The server did not answer for it: it stays pending for
                  // the next run.
                  break;
              }
            }
          case _Stop():
            stop ??= outcome;
          // Its photos were not touched: they stay pending.
        }
        if (!cancelled()) report();
      }
    }

    await Future.wait(List.generate(parallelCalls, (_) => worker()));
    final stopped = stop;
    if (stopped != null) {
      Error.throwWithStackTrace(stopped.error, stopped.stack);
    }
  }

  /// Never throws, so no failing call leaves another one running without
  /// anyone listening.
  Future<_Outcome> _analyzeCall(List<String> ids) async {
    var busyRetries = 0;
    var attempts = 0;
    while (true) {
      try {
        return _Done(await _analysis.analyze(ids));
      } on AnalysisBusyException catch (e, stack) {
        if (busyRetries >= maxBusyRetries) {
          return _Stop(
            AppException(busyMessage, kind: AppErrorKind.server, cause: e),
            stack,
          );
        }
        busyRetries++;
        await _wait(e.retryAfter);
      } catch (e, stack) {
        if (_isConnectionProblem(e)) return _Stop(e, stack);
        attempts++;
        if (attempts < maxAttempts) {
          await _wait(retryPause);
          continue;
        }
        // The call failed every time: its photos are «No analizada» so the
        // rest can go on.
        try {
          await _analysis.markFailed(ids);
          return _Done({for (final id in ids) id: PhotoAnalysisOutcome.failed});
        } catch (e, stack) {
          return _Stop(e, stack);
        }
      }
    }
  }

  bool _isConnectionProblem(Object error) {
    return error is AppException &&
        (error.kind == AppErrorKind.network ||
            error.kind == AppErrorKind.timeout);
  }
}

sealed class _Outcome {
  const _Outcome();
}

class _Done extends _Outcome {
  final Map<String, PhotoAnalysisOutcome> results;

  const _Done(this.results);
}

/// Something that stops the whole run.
class _Stop extends _Outcome {
  final Object error;
  final StackTrace stack;

  const _Stop(this.error, this.stack);
}
