import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

/// How many photos the AI already described, for «128 fotos» (HU-12, CA6).
/// The timeline loads in pages (HU-15), so the total is asked apart.
class CountAnalyzedPhotosUseCase {
  final PhotoRepository _photos = sl();

  Future<int> call() {
    return _photos.countAnalyzed();
  }
}
