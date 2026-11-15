/// How far the analysis of the imported photos has got.
class AnalysisProgress {
  /// Imported photos, analyzed or not.
  final int total;

  /// Photos that already have their title, category and tags, including the
  /// ones analyzed in an earlier run.
  final int analyzed;

  /// Photos the AI could not describe. They are left out and not retried.
  final int failed;

  const AnalysisProgress({
    required this.total,
    required this.analyzed,
    required this.failed,
  });

  @override
  String toString() =>
      'AnalysisProgress(total: $total, analyzed: $analyzed, failed: $failed)';
}
