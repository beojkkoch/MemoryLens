import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/injection_container.dart';

/// One photo with its AI analysis, for its detail (HU-28). Null when it is
/// not one of the person's photos.
class GetPhotoDetailUseCase {
  final PhotoDetailRepository _photos = sl();

  Future<PhotoDetail?> call(String id) {
    return _photos.find(id);
  }
}
