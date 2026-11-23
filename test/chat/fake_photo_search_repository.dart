import 'dart:async';

import 'package:memorylens/features/chat/domain/repository/photo_search_repository.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

/// Answers every question with the photos in [photos].
class FakePhotoSearchRepository implements PhotoSearchRepository {
  List<MemoryPhoto> photos = [];

  /// Thrown by [search] when set.
  Object? error;

  /// When set, [search] waits for it, so a test can look at «Pensando…».
  Completer<void>? gate;

  /// The questions the search was asked.
  final List<String> asked = [];

  @override
  Future<List<MemoryPhoto>> search(String question) async {
    asked.add(question);
    await gate?.future;
    if (error != null) throw error!;
    return photos;
  }
}
