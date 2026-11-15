import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Gives the photos «No analizada» another chance (HU-10, CA8): they go back
/// to the queue with their 3 attempts, and the next run of
/// AnalyzePendingPhotosUseCase sends only them, since the rest are done.
class RetryFailedPhotosUseCase {
  final PhotoAnalysisRepository _analysis = sl();

  /// Returns how many photos went back to the queue.
  Future<int> call() {
    return _analysis.retryFailed();
  }
}
