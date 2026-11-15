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

    group('after an analysis', () {
      final since = DateTime(2026, 11, 15, 10);

      test('a new photo taken today goes on top and nothing loaded is '
          'dropped', () async {
        photos.analyzedPhotos = manyPhotos(300);
        final loaded = await getMemories.next(await getMemories());
        photos.analyzedPhotos = [
          memoryPhoto('new', takenAt: DateTime(2025)),
          ...manyPhotos(300),
        ];
        photos.recentIds.add('new');

        final refreshed = await getMemories.refresh(loaded, since: since);

        expect(refreshed.photos, hasLength(2 * pageSize + 1));
        expect(refreshed.groups.first.photos.first.id, 'new');
        expect(refreshed.hasMore, isTrue);
      });

      test('a new photo taken long ago goes under its own day', () async {
        photos.analyzedPhotos = manyPhotos(300);
        final loaded = await getMemories.next(await getMemories());
        // Taken between two photos already loaded: p10 and p11.
        final old = memoryPhoto(
          'old',
          takenAt: DateTime(2024, 6, 15).subtract(const Duration(minutes: 630)),
        );
        photos.analyzedPhotos = [
          ...manyPhotos(300).take(11),
          old,
          ...manyPhotos(300).skip(11),
        ];
        photos.recentIds.add('old');

        final refreshed = await getMemories.refresh(loaded, since: since);
        final ids = [
          for (final group in refreshed.groups)
            for (final photo in group.photos) photo.id,
        ];
        expect(ids.sublist(10, 13), ['p10', 'old', 'p11']);

        // The next page goes on right after the last loaded one: none is
        // skipped and none repeats.
        final next = await getMemories.next(refreshed);
        final nextIds = next.photos.map((p) => p.id).toList();
        expect(nextIds.toSet(), hasLength(nextIds.length));
        expect(nextIds, hasLength(3 * pageSize + 1));
        expect(nextIds, contains('p${2 * pageSize}'));
      });

      test(
        'one taken before the oldest loaded is left for the next pages',
        () async {
          photos.analyzedPhotos = manyPhotos(300);
          final loaded = await getMemories();

          await getMemories.refresh(loaded, since: since);

          expect(photos.sinceTakenAfter, [
            loaded.groups.last.photos.last.takenAt,
          ]);
        },
      );

      test('with everything loaded any new photo comes in', () async {
        photos.analyzedPhotos = manyPhotos(3);
        final loaded = await getMemories();
        photos.analyzedPhotos = [
          ...manyPhotos(3),
          memoryPhoto('older', takenAt: DateTime(2020)),
        ];
        photos.recentIds.add('older');

        final refreshed = await getMemories.refresh(loaded, since: since);

        expect(photos.sinceTakenAfter, [null]);
        expect(refreshed.groups.last.photos.single.id, 'older');
        expect(refreshed.hasMore, isFalse);
      });
    });
  });
}
