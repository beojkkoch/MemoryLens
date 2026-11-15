import 'package:memorylens/features/photo_analysis/data/source/supabase_photo_analysis_data_source.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_backlog.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/injection_container.dart';

class PhotoAnalysisRepositoryImpl implements PhotoAnalysisRepository {
  final SupabasePhotoAnalysisDataSource _dataSource = sl();

  @override
  Future<AnalysisBacklog> backlog() async {
    final results = await Future.wait([
      _dataSource.pendingPhotoIds(),
      _dataSource.countInState('listo'),
      _dataSource.countInState('error'),
    ]);
    return AnalysisBacklog(
      pendingIds: results[0] as List<String>,
      analyzed: results[1] as int,
      failed: results[2] as int,
    );
  }

  @override
  Future<bool> hasPendingAnalysis() async {
    return await _dataSource.countInState('pendiente') > 0;
  }

  @override
  Future<Map<String, PhotoAnalysisOutcome>> analyze(List<String> photoIds) {
    return _dataSource.analyze(photoIds);
  }

  @override
  Future<void> markFailed(List<String> photoIds) {
    return _dataSource.markFailed(photoIds);
  }
}
