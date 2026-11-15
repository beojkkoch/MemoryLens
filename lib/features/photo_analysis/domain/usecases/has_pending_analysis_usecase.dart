import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Tells whether some imported photo still has no title, category or tags,
/// for example because the app was closed in the middle of the analysis.
class HasPendingAnalysisUseCase {
  final PhotoAnalysisRepository _analysis = sl();

  Future<bool> call() {
    return _analysis.hasPendingAnalysis();
  }
}
