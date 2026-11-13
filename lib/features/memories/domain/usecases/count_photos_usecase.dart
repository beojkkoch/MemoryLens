import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Tells how many photos the person already has, to know if Recuerdos shows
/// the empty gallery or the photos.
class CountPhotosUseCase {
  final PhotoRepository _photos = sl();

  Future<int> call() {
    return _photos.count();
  }
}
