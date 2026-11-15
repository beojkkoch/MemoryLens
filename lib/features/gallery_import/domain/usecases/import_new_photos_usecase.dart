import 'dart:math';

import 'package:memorylens/features/gallery_import/domain/usecases/import_gallery_photos_usecase.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
import 'package:memorylens/injection_container.dart';

/// Imports and analyzes the new photos of the device without any screen in
/// between (HU-11, CA2). It runs the same steps as the first import (HU-07)
/// and its analysis (HU-08), so the photos already processed are left out and
/// a failing photo is retried like in HU-10.
class ImportNewPhotosUseCase {
  final ImportGalleryPhotosUseCase _import = sl();
  final AnalyzePendingPhotosUseCase _analyze = sl();
  final PhotoAnalysisRepository _analysis = sl();

  /// Returns how many photos this run analyzed, for «N nuevas fotos
  /// analizadas» (HU-11, CA3). A lost connection or any other failure is
  /// thrown: what was done is kept, and the next run goes on from there.
  Future<int> call() async {
    final before = (await _analysis.doneCounts()).analyzed;
    await _import().drain<void>();
    await _analyze().drain<void>();
    final after = (await _analysis.doneCounts()).analyzed;
    return max(0, after - before);
  }
}
