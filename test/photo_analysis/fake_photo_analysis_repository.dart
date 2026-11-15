import 'dart:async';

import 'package:memorylens/features/photo_analysis/domain/entities/analysis_backlog.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';

/// Behaves like the foto table and the analizar-fotos function: every
/// imported photo is pending until it is analyzed, and a photo the AI cannot
/// describe goes back to the queue until it used its 3 attempts.
class FakePhotoAnalysisRepository implements PhotoAnalysisRepository {
  /// Attempts of a photo before the server marks it «No analizada».
  static const serverAttempts = 3;

  /// [_importedIds] gives the ids of the imported photos. By default they are
  /// the ones added to [extraPhotos]; the import fakes pass their own.
  FakePhotoAnalysisRepository({this._importedIds});

  final Iterable<String> Function()? _importedIds;

  /// Imported photos when no [importedIds] was given.
  final List<String> extraPhotos = [];

  /// Photos no longer pending: analyzed or «No analizada».
  final Map<String, PhotoAnalysisOutcome> done = {};

  /// Failed attempts of each photo, like foto.intentos_analisis.
  final Map<String, int> attempts = {};

  /// Every call to [analyze], with its ids.
  final List<List<String>> calls = [];

  /// The AI never manages to describe these.
  final Set<String> blocked = {};

  /// The AI fails these that many times, then describes them.
  final Map<String, int> flaky = {};

  /// Thrown (once each) by the next calls to [analyze], in order.
  final List<Object> nextErrors = [];

  /// Every call with one of these photos throws its error.
  final Map<String, Object> callErrors = {};

  /// Photos marked «No analizada» by the app with [markFailed].
  final List<String> markedFailed = [];

  /// While set, every call waits for it. Keeps an analysis half done.
  Completer<void>? gate;

  /// Calls before this one do not wait for [gate], so the analysis stops
  /// part of the way. Null: every call waits.
  int? gateFromCall;

  /// Thrown by [backlog] when set.
  Object? backlogError;

  /// Thrown by [retryFailed] when set.
  Object? retryFailedError;

  /// Times [retryFailed] was called.
  int retryFailedCalls = 0;

  /// Times [doneCounts] was called.
  int doneCountsCalls = 0;

  Iterable<String> get _imported => _importedIds?.call() ?? extraPhotos;

  @override
  Future<AnalysisBacklog> backlog() async {
    if (backlogError != null) throw backlogError!;
    return AnalysisBacklog(
      pendingIds: _imported.where((id) => !done.containsKey(id)).toList(),
      analyzed: done.values
          .where((o) => o == PhotoAnalysisOutcome.analyzed)
          .length,
      failed: done.values.where((o) => o == PhotoAnalysisOutcome.failed).length,
    );
  }

  @override
  Future<({int analyzed, int failed})> doneCounts() async {
    doneCountsCalls++;
    return (
      analyzed: done.values
          .where((o) => o == PhotoAnalysisOutcome.analyzed)
          .length,
      failed: done.values.where((o) => o == PhotoAnalysisOutcome.failed).length,
    );
  }

  /// Like reintentar_fotos_no_analizadas: back to pending, attempts at 0.
  @override
  Future<int> retryFailed() async {
    retryFailedCalls++;
    if (retryFailedError != null) throw retryFailedError!;
    final failed = done.entries
        .where((e) => e.value == PhotoAnalysisOutcome.failed)
        .map((e) => e.key)
        .toList();
    for (final id in failed) {
      done.remove(id);
      attempts.remove(id);
    }
    return failed.length;
  }

  @override
  Future<bool> hasPendingAnalysis() async {
    return _imported.any((id) => !done.containsKey(id));
  }

  @override
  Future<Map<String, PhotoAnalysisOutcome>> analyze(
    List<String> photoIds,
  ) async {
    if (photoIds.length > PhotoAnalysisRepository.maxPhotosPerCall) {
      throw StateError('too many photos in one call');
    }
    calls.add(photoIds);
    if (calls.length > (gateFromCall ?? 0)) await gate?.future;
    if (nextErrors.isNotEmpty) throw nextErrors.removeAt(0);
    for (final id in photoIds) {
      final error = callErrors[id];
      if (error != null) throw error;
    }
    return {for (final id in photoIds) id: _analyzeOne(id)};
  }

  PhotoAnalysisOutcome _analyzeOne(String id) {
    final already = done[id];
    if (already != null) return already;

    final failsLeft = flaky[id] ?? 0;
    if (!blocked.contains(id) && failsLeft == 0) {
      return done[id] = PhotoAnalysisOutcome.analyzed;
    }
    if (failsLeft > 0) flaky[id] = failsLeft - 1;
    final tries = attempts[id] = (attempts[id] ?? 0) + 1;
    if (tries >= serverAttempts) return done[id] = PhotoAnalysisOutcome.failed;
    return PhotoAnalysisOutcome.retry;
  }

  @override
  Future<void> markFailed(List<String> photoIds) async {
    markedFailed.addAll(photoIds);
    for (final id in photoIds) {
      done.putIfAbsent(id, () => PhotoAnalysisOutcome.failed);
    }
  }
}
