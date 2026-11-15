import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/get_memories_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_photo_repository.dart';

void main() {
  late FakePhotoRepository photos;
  late GetMemoriesUseCase getMemories;

  const pageSize = GetMemoriesUseCase.pageSize;

  setUp(() async {
    await sl.reset();
    photos = FakePhotoRepository();
    sl.registerSingleton<PhotoRepository>(photos);
    getMemories = GetMemoriesUseCase();
  });

  group('the timeline in pages (HU-15)', () {
    test('the first load brings only the newest page (CA1)', () async {
      photos.analyzedPhotos = manyPhotos(1000);

      final timeline = await getMemories();

      expect(timeline.photos, hasLength(pageSize));
      expect(timeline.photos.first.id, 'p0');
      expect(timeline.hasMore, isTrue);
      expect(photos.pageOffsets, [0]);
    });

    test('the next page goes after the loaded ones (CA2)', () async {
      photos.analyzedPhotos = manyPhotos(1000);

      final first = await getMemories();
      final second = await getMemories.next(first);

      expect(photos.pageOffsets, [0, pageSize]);
      expect(second.photos, hasLength(2 * pageSize));
      expect(second.photos.last.id, 'p${2 * pageSize - 1}');
      expect(second.groups.expand((g) => g.photos), hasLength(2 * pageSize));
    });

    test('a short page is the last one', () async {
      photos.analyzedPhotos = manyPhotos(pageSize + 5);

      final first = await getMemories();
      final last = await getMemories.next(first);

      expect(last.photos, hasLength(pageSize + 5));
      expect(last.hasMore, isFalse);
    });

    test('a person with few photos has no more to load', () async {
      photos.analyzedPhotos = manyPhotos(3);

      final timeline = await getMemories();

      expect(timeline.photos, hasLength(3));
      expect(timeline.hasMore, isFalse);
    });

    test('a photo that moved to the next page does not repeat', () async {
      photos.analyzedPhotos = manyPhotos(200);
      final first = await getMemories();
      // A photo that came in pushes the rest one place down.
      photos.analyzedPhotos = [
        memoryPhoto('new', takenAt: DateTime(2025)),
        ...manyPhotos(200),
      ];

      final second = await getMemories.next(first);
      final ids = second.photos.map((p) => p.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, contains('p${pageSize - 1}'));
    });

    test('after an analysis the newest page comes back on top and the rest '
        'stays loaded', () async {
      photos.analyzedPhotos = manyPhotos(300);
      final loaded = await getMemories.next(await getMemories());
      photos.analyzedPhotos = [
        memoryPhoto('new', takenAt: DateTime(2025)),
        ...manyPhotos(300),
      ];

      final refreshed = await getMemories.refresh(loaded);

      expect(refreshed.photos, hasLength(2 * pageSize + 1));
      expect(refreshed.groups.first.photos.first.id, 'new');
      expect(refreshed.hasMore, isTrue);
    });
  });
}
