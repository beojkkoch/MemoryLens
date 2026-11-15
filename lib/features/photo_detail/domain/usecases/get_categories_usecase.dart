import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/injection_container.dart';

/// The categories of the system, to correct the one of a photo (HU-30, CA5).
class GetCategoriesUseCase {
  final PhotoDetailRepository _photos = sl();

  Future<List<String>> call() {
    return _photos.categories();
  }
}
