import 'dart:async';

import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';

/// Serves the photo count and the analyzed photos the backend would have.
class FakePhotoRepository implements PhotoRepository {
  int photoCount = 0;

  /// The analyzed photos of the account, newest first. [analyzed] serves
  /// them in pages.
  List<MemoryPhoto> analyzedPhotos = [];

  /// Each later call to [count] takes the next of these first, like the
  /// account after an analysis.
  final List<List<MemoryPhoto>> laterAnalyzed = [];

  /// Thrown by every method when set.
  Object? error;

  /// Thrown only when asking for a page after the first.
  Object? nextPageError;

  /// When set, the pages after the first wait for it.
  Completer<void>? nextPageGate;

  int countCalls = 0;

  /// The offset of every page asked for.
  final List<int> pageOffsets = [];

  @override
  Future<int> count() async {
    if (countCalls > 0 && laterAnalyzed.isNotEmpty) {
      analyzedPhotos = laterAnalyzed.removeAt(0);
    }
    countCalls++;
    if (error != null) throw error!;
    return photoCount;
  }

  @override
  Future<int> countAnalyzed() async {
    if (error != null) throw error!;
    return analyzedPhotos.length;
  }

  @override
  Future<List<MemoryPhoto>> analyzed({
    required int offset,
    required int limit,
  }) async {
    pageOffsets.add(offset);
    if (error != null) throw error!;
    if (offset > 0) {
      await nextPageGate?.future;
      if (nextPageError != null) throw nextPageError!;
    }
    return analyzedPhotos.skip(offset).take(limit).toList();
  }
}

/// An analyzed photo with no links, so no test goes to the network.
MemoryPhoto memoryPhoto(String id, {String? title, DateTime? takenAt}) {
  return MemoryPhoto(id: id, title: title ?? 'Foto $id', takenAt: takenAt);
}

/// [count] photos, one an hour back from June 15 2024, newest first.
List<MemoryPhoto> manyPhotos(int count) {
  return [
    for (var i = 0; i < count; i++)
      memoryPhoto(
        'p$i',
        takenAt: DateTime(2024, 6, 15).subtract(Duration(hours: i)),
      ),
  ];
}
