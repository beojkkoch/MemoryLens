/// What happened to one photo sent to the AI.
enum PhotoAnalysisOutcome {
  /// It has its title, category, tags and embeddings.
  analyzed,

  /// The AI could not describe it (blocked or unreadable). It is not retried.
  failed,
}
