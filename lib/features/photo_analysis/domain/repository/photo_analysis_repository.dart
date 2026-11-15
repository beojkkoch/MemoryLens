import 'package:memorylens/features/photo_analysis/domain/entities/analysis_backlog.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';

/// Sends the imported photos to the AI, which writes a title, a category and
/// tags in Spanish for each one and saves them with its embeddings.
abstract class PhotoAnalysisRepository {
  /// Most photos in one call to [analyze].
  static const maxPhotosPerCall = 4;

  /// The photos still waiting and how many are already done.
  Future<AnalysisBacklog> backlog();

  /// Whether any imported photo is still waiting for the AI.
  Future<bool> hasPendingAnalysis();

  /// Analyzes up to [maxPhotosPerCall] photos and saves the result. Asking
  /// for a photo already analyzed is safe: it is not sent again.
  ///
  /// Throws AnalysisBusyException when the AI asks to wait.
  Future<Map<String, PhotoAnalysisOutcome>> analyze(List<String> photoIds);

  /// Marks the photos as «No analizada», for when every attempt to analyze
  /// them failed. Photos already analyzed are left as they are.
  Future<void> markFailed(List<String> photoIds);
}
