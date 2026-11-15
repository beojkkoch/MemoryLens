import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';

/// Serves the photo count and the analyzed photos the backend would have.
class FakePhotoRepository implements PhotoRepository {
  int photoCount = 0;

  /// What [analyzed] returns.
  List<MemoryPhoto> analyzedPhotos = [];

  /// Each later call to [analyzed] takes the next of these first, like the
  /// account after an analysis.
  final List<List<MemoryPhoto>> laterAnalyzed = [];

  /// Thrown by [count] and [analyzed] when set.
  Object? error;

  int countCalls = 0;
  int analyzedCalls = 0;

  @override
  Future<int> count() async {
    countCalls++;
    if (error != null) throw error!;
    return photoCount;
  }

  @override
  Future<List<MemoryPhoto>> analyzed() async {
    if (analyzedCalls > 0 && laterAnalyzed.isNotEmpty) {
      analyzedPhotos = laterAnalyzed.removeAt(0);
    }
    analyzedCalls++;
    if (error != null) throw error!;
    return analyzedPhotos;
  }
}

/// An analyzed photo with no links, so no test goes to the network.
MemoryPhoto memoryPhoto(String id, {String? title, DateTime? takenAt}) {
  return MemoryPhoto(id: id, title: title ?? 'Foto $id', takenAt: takenAt);
}
