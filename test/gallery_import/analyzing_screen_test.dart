import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/injection_container.dart';

import 'gallery_import_test_setup.dart';

void main() {
  late GalleryImportFakes fakes;

  setUp(() async {
    await sl.reset();
    fakes = registerGalleryImportFakes();
  });

  Future<void> pumpAnalyzing(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/analizando',
        routes: {
          '/analizando': (_) => analyzingRoute(),
          '/recuerdos': (_) => const Scaffold(body: Text('Pantalla Recuerdos')),
        },
      ),
    );
    await settle(tester);
  }

  /// Holds the analysis so the screen can be looked at while it works.
  void holdAnalysis({int? fromCall}) {
    fakes.analysis.gate = Completer<void>();
    fakes.analysis.gateFromCall = fromCall;
    addTearDown(() => fakes.analysis.gate!.complete());
  }

  group('import', () {
    testWidgets('while the photos are imported it says how many are ready', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.photos.gate = Completer<void>();
      addTearDown(() => fakes.photos.gate!.complete());

      await pumpAnalyzing(tester);

      expect(find.text('Analizando'), findsOneWidget);
      expect(find.text('Preparando tus fotos…'), findsOneWidget);
      expect(find.text('Preparadas 0 de 2 fotos'), findsOneWidget);
      expect(find.text('0 %'), findsOneWidget);
    });

    testWidgets('without connection it says it is waiting', (tester) async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.photos.uploadErrors['p1'] = const AppException(
        'No pudimos conectarnos.',
        kind: AppErrorKind.network,
      );
      fakes.network.online = false;

      await pumpAnalyzing(tester);

      expect(find.text('Esperando conexión'), findsOneWidget);
      expect(
        find.text('Seguiremos donde quedamos en cuanto vuelva internet.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('goes on by itself when the connection is back', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.photos.uploadErrors['p1'] = const AppException(
        'No pudimos conectarnos.',
        kind: AppErrorKind.network,
      );
      fakes.network.online = false;
      await pumpAnalyzing(tester);
      expect(find.text('Esperando conexión'), findsOneWidget);

      fakes.photos.uploadErrors.clear();
      fakes.network.setOnline(true);
      await settle(tester);

      expect(find.text('¡Listo!'), findsOneWidget);
      expect(fakes.photos.imported, {'p0', 'p1'});
    });

    testWidgets('a failure shows the reason and «Reintentar» recovers', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.gallery.listError = const AppException(
        'Memory Lens no tiene acceso a tus fotos.',
      );

      await pumpAnalyzing(tester);

      expect(
        find.text('Memory Lens no tiene acceso a tus fotos.'),
        findsOneWidget,
      );
      fakes.gallery.listError = null;
      await tester.tap(find.text('Reintentar'));
      await settle(tester);

      expect(find.text('¡Listo!'), findsOneWidget);
    });
  });

  group('analysis progress (HU-10)', () {
    testWidgets('shows the ring, «Analizadas X de N fotos» and the percent', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(2);
      holdAnalysis();

      await pumpAnalyzing(tester);

      expect(find.text('Analizando tu galería…'), findsOneWidget);
      expect(find.text('Analizadas 0 de 2 fotos'), findsOneWidget);
      expect(find.text('0 %'), findsOneWidget);
      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, 0);
    });

    testWidgets('the numbers are the photos really processed', (tester) async {
      // 12 photos are 3 calls: the first two end, the third one is held.
      fakes.gallery.photos = devicePhotos(12);
      holdAnalysis(fromCall: 2);

      await pumpAnalyzing(tester);

      expect(find.text('Analizadas 8 de 12 fotos'), findsOneWidget);
      expect(find.text('66 %'), findsOneWidget);
      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, closeTo(0.66, 0.001));
    });

    testWidgets('after a restart it starts from the saved progress', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(4);
      fakes.photos.imported.addAll({'p0', 'p1', 'p2', 'p3'});
      fakes.analysis.done['p0'] = PhotoAnalysisOutcome.analyzed;
      fakes.analysis.done['p1'] = PhotoAnalysisOutcome.failed;
      holdAnalysis();

      await pumpAnalyzing(tester);

      expect(find.text('Analizadas 1 de 4 fotos'), findsOneWidget);
      expect(find.text('1 foto no analizada'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);
    });

    testWidgets('says how many photos could not be analyzed', (tester) async {
      fakes.gallery.photos = devicePhotos(3);
      fakes.analysis.blocked.addAll({'p0', 'p2'});

      await pumpAnalyzing(tester);

      expect(find.text('Analizadas 1 de 3 fotos'), findsOneWidget);
      expect(find.text('2 fotos no analizadas'), findsOneWidget);
      expect(find.text('100 %'), findsOneWidget);
      // Each of them was tried 3 times.
      expect(fakes.analysis.attempts, {'p0': 3, 'p2': 3});
    });

    testWidgets(
      'a failed analysis keeps the import and «Reintentar» recovers',
      (tester) async {
        fakes.gallery.photos = devicePhotos(2);
        fakes.analysis.backlogError = const AppException(
          'Tuvimos un problema de nuestro lado.',
          kind: AppErrorKind.server,
        );

        await pumpAnalyzing(tester);

        expect(
          find.text('Tuvimos un problema de nuestro lado.'),
          findsOneWidget,
        );
        fakes.analysis.backlogError = null;
        final uploadsBefore = Map.of(fakes.photos.uploadCounts);
        await tester.tap(find.text('Reintentar'));
        await settle(tester);

        expect(find.text('¡Listo!'), findsOneWidget);
        // Retrying the analysis does not import the photos again.
        expect(fakes.photos.uploadCounts, uploadsBefore);
      },
    );

    testWidgets('with photos «No analizada» it waits on «Reintentar» '
        '(HU-10, CA8)', (tester) async {
      fakes.gallery.photos = devicePhotos(3);
      fakes.analysis.blocked.add('p1');

      await pumpAnalyzing(tester);
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);

      // It does not leave by itself: the person decides.
      expect(find.byType(AnalyzingScreen), findsOneWidget);
      expect(find.text('1 foto no analizada'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Ver mis recuerdos'), findsOneWidget);

      fakes.analysis.blocked.clear();
      fakes.analysis.calls.clear();
      await tester.tap(find.text('Reintentar'));
      await settle(tester);

      expect(fakes.analysis.calls, [
        ['p1'],
      ]);
      expect(find.text('Analizadas 3 de 3 fotos'), findsOneWidget);
      expect(find.text('1 foto no analizada'), findsNothing);

      // Now that every photo is analyzed, it opens Recuerdos by itself.
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(find.text('Pantalla Recuerdos'), findsOneWidget);
    });

    testWidgets('«Ver mis recuerdos» leaves the failed photos for later', (
      tester,
    ) async {
      fakes.gallery.photos = devicePhotos(2);
      fakes.analysis.blocked.add('p0');

      await pumpAnalyzing(tester);
      await tester.tap(find.text('Ver mis recuerdos'));
      await settle(tester);

      expect(find.text('Pantalla Recuerdos'), findsOneWidget);
      expect(fakes.analysis.retryFailedCalls, 0);
    });

    testWidgets('at 100 % it opens Recuerdos by itself', (tester) async {
      fakes.gallery.photos = devicePhotos(3);

      await pumpAnalyzing(tester);

      expect(find.text('¡Listo!'), findsOneWidget);
      expect(find.text('Analizadas 3 de 3 fotos'), findsOneWidget);
      expect(find.text('100 %'), findsOneWidget);
      expect(fakes.analysis.done.keys.toSet(), {'p0', 'p1', 'p2'});

      await tester.pump(const Duration(seconds: 1));
      await settle(tester);

      expect(find.text('Pantalla Recuerdos'), findsOneWidget);
      expect(find.byType(AnalyzingScreen), findsNothing);
    });
  });
}

/// Lets the blocs work and the screen change for one second. It cannot use
/// pumpAndSettle because the ring of the working states never stops.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
