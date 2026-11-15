import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_busy_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_progress.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/photo_analysis/domain/repository/photo_analysis_repository.dart';
import 'package:memorylens/features/photo_analysis/domain/usecases/analyze_pending_photos_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_photo_analysis_repository.dart';

void main() {
  const noConnection = AppException(
    'No pudimos conectarnos.',
    kind: AppErrorKind.network,
  );

  late FakePhotoAnalysisRepository analysis;
  late List<Duration> waits;
  late AnalyzePendingPhotosUseCase analyze;

  setUp(() async {
    await sl.reset();
    analysis = FakePhotoAnalysisRepository();
    sl.registerSingleton<PhotoAnalysisRepository>(analysis);
    waits = [];
    analyze = AnalyzePendingPhotosUseCase(wait: (d) async => waits.add(d));
  });

  List<String> photos(int count) => List.generate(count, (i) => 'f$i');

  test('analyzes every pending photo, a few per call', () async {
    analysis.extraPhotos.addAll(photos(10));

    final progress = await analyze().toList();

    expect(progress.first.total, 10);
    expect(progress.first.analyzed, 0);
    expect(progress.last.analyzed, 10);
    expect(progress.last.failed, 0);
    expect(analysis.calls.map((c) => c.length), [4, 4, 2]);
    expect(analysis.done.keys.toSet(), photos(10).toSet());
  });

  test('128 photos take 32 calls, two at a time (CA6)', () async {
    analysis.extraPhotos.addAll(photos(128));

    final progress = await analyze().toList();

    expect(analysis.calls, hasLength(32));
    // The first emit plus one per round of two calls.
    expect(progress, hasLength(1 + 16));
    expect(progress.last.analyzed, 128);
  });

  test('goes on from where it stopped and does not resend photos', () async {
    analysis.extraPhotos.addAll(photos(6));
    analysis.done['f0'] = PhotoAnalysisOutcome.analyzed;
    analysis.done['f1'] = PhotoAnalysisOutcome.failed;

    final progress = await analyze().toList();

    expect(progress.first.total, 6);
    expect(progress.first.analyzed, 1);
    expect(progress.first.failed, 1);
    expect(analysis.calls.expand((c) => c), ['f2', 'f3', 'f4', 'f5']);
    expect(progress.last.analyzed, 5);
  });

  test('nothing pending is not a call', () async {
    final progress = await analyze().toList();

    expect(progress, hasLength(1));
    expect(progress.single.total, 0);
    expect(analysis.calls, isEmpty);
  });

  test('a photo the AI cannot describe does not stop the others', () async {
    analysis.extraPhotos.addAll(photos(5));
    analysis.blocked.add('f2');

    final last = await analyze().last;

    expect(last.analyzed, 4);
    expect(last.failed, 1);
  });

  test('waits when the AI asks to and tries the same call again', () async {
    analysis.extraPhotos.addAll(photos(3));
    analysis.nextErrors.add(const AnalysisBusyException(Duration(seconds: 30)));

    final last = await analyze().last;

    expect(waits, [const Duration(seconds: 30)]);
    expect(analysis.calls, [
      ['f0', 'f1', 'f2'],
      ['f0', 'f1', 'f2'],
    ]);
    expect(last.analyzed, 3);
  });

  test('gives up with a clear message when the AI stays busy', () async {
    analysis.extraPhotos.addAll(photos(2));
    for (var i = 0; i <= AnalyzePendingPhotosUseCase.maxBusyRetries; i++) {
      analysis.nextErrors.add(
        const AnalysisBusyException(Duration(seconds: 5)),
      );
    }

    await expectLater(
      analyze().last,
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          AnalyzePendingPhotosUseCase.busyMessage,
        ),
      ),
    );
    expect(waits, hasLength(AnalyzePendingPhotosUseCase.maxBusyRetries));
    expect(analysis.done, isEmpty);
  });

  test(
    'a lost connection is thrown after counting the rest of the round',
    () async {
      analysis.extraPhotos.addAll(photos(8));
      // The first round is two calls: one fails, the other one goes through.
      analysis.nextErrors.add(noConnection);
      final emitted = <AnalysisProgress>[];

      await expectLater(
        analyze().forEach(emitted.add),
        throwsA(same(noConnection)),
      );
      expect(analysis.calls, hasLength(2));
      expect(emitted.last.analyzed, 4);

      // Running it again only sends the photos still pending.
      analysis.calls.clear();
      final last = await analyze().last;
      expect(analysis.calls, hasLength(1));
      expect(analysis.calls.single, hasLength(4));
      expect(last.analyzed, 8);
    },
  );
}
