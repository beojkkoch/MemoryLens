import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/memories/domain/entities/memory_group.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';

import 'fake_photo_repository.dart';

void main() {
  group('photos grouped by day (HU-12)', () {
    test('by the day they were taken, newest day first (CA2, CA3)', () {
      final groups = MemoryGroup.byDay([
        memoryPhoto('june14', takenAt: DateTime(2024, 6, 14, 20)),
        memoryPhoto('june15', takenAt: DateTime(2024, 6, 15, 8)),
        memoryPhoto('may', takenAt: DateTime(2024, 5, 1)),
      ]);

      expect(groups.map((g) => g.day), [
        DateTime(2024, 6, 15),
        DateTime(2024, 6, 14),
        DateTime(2024, 5, 1),
      ]);
    });

    test('newest photo first inside each day (CA4)', () {
      final groups = MemoryGroup.byDay([
        memoryPhoto('morning', takenAt: DateTime(2024, 6, 15, 8)),
        memoryPhoto('night', takenAt: DateTime(2024, 6, 15, 22)),
        memoryPhoto('noon', takenAt: DateTime(2024, 6, 15, 12)),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.photos.map((p) => p.id), [
        'night',
        'noon',
        'morning',
      ]);
    });

    test('the photos with no capture date go last', () {
      final groups = MemoryGroup.byDay([
        memoryPhoto('unknown'),
        memoryPhoto('june', takenAt: DateTime(2024, 6, 15)),
      ]);

      expect(groups.map((g) => g.day), [DateTime(2024, 6, 15), null]);
    });

    test('no photos, no groups', () {
      expect(MemoryGroup.byDay([]), isEmpty);
    });
  });

  group('dates in Spanish (HU-12)', () {
    final now = DateTime(2024, 6, 15, 10);

    test('«Hoy», «Ayer» and then the date (CA2)', () {
      expect(MemoryDates.dayLabel(DateTime(2024, 6, 15), now), 'Hoy');
      expect(MemoryDates.dayLabel(DateTime(2024, 6, 14), now), 'Ayer');
      expect(MemoryDates.dayLabel(DateTime(2024, 6, 13), now), '13 jun 2024');
      expect(MemoryDates.dayLabel(DateTime(2023, 12, 5), now), '5 dic 2023');
    });

    test('«Ayer» also works across months', () {
      expect(
        MemoryDates.dayLabel(DateTime(2024, 5, 31), DateTime(2024, 6, 1)),
        'Ayer',
      );
    });

    test('a photo with no date says so', () {
      expect(MemoryDates.dayLabel(null, now), 'Sin fecha');
    });

    test('month and year of the header (CA5)', () {
      expect(MemoryDates.monthLabel(DateTime(2024, 6, 15)), 'Junio 2024');
      expect(MemoryDates.monthLabel(DateTime(2025, 1, 2)), 'Enero 2025');
    });
  });
}
