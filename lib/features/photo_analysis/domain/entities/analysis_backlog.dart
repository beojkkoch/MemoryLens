/// What is left to analyze, and what was already done in earlier runs.
class AnalysisBacklog {
  /// Ids in the foto table of the photos still waiting for the AI.
  final List<String> pendingIds;

  final int analyzed;
  final int failed;

  const AnalysisBacklog({
    required this.pendingIds,
    required this.analyzed,
    required this.failed,
  });
}
