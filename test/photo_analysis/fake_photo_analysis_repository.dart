import 'dart:async';

import 'package:memorylens/features/photo_analysis/domain/entities/analysis_backlog.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';

/// Behaves like the foto table and the analizar-fotos function: every
/// imported photo is pending until it is analyzed.
class FakePhotoAnalysisRepository implements PhotoAnalysisRepository {
  /// [_importedIds] gives the ids of the imported photos. By default they are
  /// the ones added to [extraPhotos]; the import fakes pass their own.
  FakePhotoAnalysisRepository({this._importedIds});

  final Iterable<String> Function()? _importedIds;

  /// Imported photos when no [importedIds] was given.
  final List<String> extraPhotos = [];

  final Map<String, PhotoAnalysisOutcome> done = {};

  /// Every call to [analyze], with its ids.
  final List<List<String>> calls = [];

  /// The AI cannot describe these.
  final Set<String> blocked = {};

  /// Thrown (once each) by the next calls to [analyze], in order.
  final List<Object> nextErrors = [];

  /// While set, every call waits for it. Keeps an analysis half done.
  Completer<void>? gate;

  /// Thrown by [backlog] when set.
  Object? backlogError;

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
    await gate?.future;
    if (nextErrors.isNotEmpty) throw nextErrors.removeAt(0);
    return {
      for (final id in photoIds)
        id: done[id] ??= blocked.contains(id)
            ? PhotoAnalysisOutcome.failed
            : PhotoAnalysisOutcome.analyzed,
    };
  }
}
