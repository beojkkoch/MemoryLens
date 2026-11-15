import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';

/// Serves the photos the backend would have. A photo not in [details] is
/// one that does not exist or is someone else's.
class FakePhotoDetailRepository implements PhotoDetailRepository {
  final Map<String, PhotoDetail> details = {};

  /// When true, any id not in [details] is a photo titled «Foto» and the id.
  bool answerEveryId = false;

  /// Thrown by [find] when set.
  Object? error;

  final List<String> asked = [];

  @override
  Future<PhotoDetail?> find(String id) async {
    asked.add(id);
    if (error != null) throw error!;
    return details[id] ??
        (answerEveryId ? PhotoDetail(id: id, title: 'Foto $id') : null);
  }
}
