import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';

/// Serves the photo count the backend would have.
class FakePhotoRepository implements PhotoRepository {
  int photoCount = 0;

  /// Thrown by [count] when set.
  Object? error;

  int countCalls = 0;

  @override
  Future<int> count() async {
    countCalls++;
    if (error != null) throw error!;
    return photoCount;
  }
}
