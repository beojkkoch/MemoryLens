/// What happened to one photo sent to the AI.
enum PhotoAnalysisOutcome {
  /// It has its title, category, tags and embeddings.
  analyzed,

  /// The AI could not describe it this time, but it has attempts left: it goes
  /// back to the queue (HU-10, up to 3 attempts in all).
  retry,

  /// «No analizada»: it failed every attempt and is not retried again.
  failed,
}
