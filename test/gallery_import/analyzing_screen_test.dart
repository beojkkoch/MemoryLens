import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
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

  testWidgets('while the photos are imported it says it is preparing them', (
    tester,
  ) async {
    fakes.gallery.photos = devicePhotos(2);
    fakes.photos.gate = Completer<void>();
    addTearDown(() => fakes.photos.gate!.complete());

    await pumpAnalyzing(tester);

    expect(find.text('Analizando'), findsOneWidget);
    expect(find.text('Estamos preparando tus fotos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Ver recuerdos'), findsNothing);
  });

  testWidgets('without connection it says it is waiting and keeps its place', (
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
    expect(
      find.text('Seguiremos donde quedamos en cuanto vuelva internet.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('goes on by itself when the connection is back', (tester) async {
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

    expect(find.text('Listo'), findsOneWidget);
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
    expect(find.text('Reintentar'), findsOneWidget);

    fakes.gallery.listError = null;
    await tester.tap(find.text('Reintentar'));
    await settle(tester);

    expect(find.text('Listo'), findsOneWidget);
    expect(find.text('Memory Lens no tiene acceso a tus fotos.'), findsNothing);
  });

  testWidgets('after the import the AI describes the photos', (tester) async {
    fakes.gallery.photos = devicePhotos(2);
    fakes.analysis.gate = Completer<void>();
    addTearDown(() => fakes.analysis.gate!.complete());

    await pumpAnalyzing(tester);

    expect(fakes.photos.imported, {'p0', 'p1'});
    expect(find.text('Estamos organizando tus recuerdos'), findsOneWidget);
    expect(find.text('Ver recuerdos'), findsNothing);
  });

  testWidgets('a failed analysis keeps the import and «Reintentar» recovers', (
    tester,
  ) async {
    fakes.gallery.photos = devicePhotos(2);
    fakes.analysis.backlogError = const AppException(
      'Tuvimos un problema de nuestro lado.',
      kind: AppErrorKind.server,
    );

    await pumpAnalyzing(tester);

    expect(find.text('Tuvimos un problema de nuestro lado.'), findsOneWidget);
    fakes.analysis.backlogError = null;
    final uploadsBefore = Map.of(fakes.photos.uploadCounts);
    await tester.tap(find.text('Reintentar'));
    await settle(tester);

    expect(find.text('Listo'), findsOneWidget);
    // Retrying the analysis does not import the photos again.
    expect(fakes.photos.uploadCounts, uploadsBefore);
  });

  testWidgets('says how many photos could not be analyzed', (tester) async {
    fakes.gallery.photos = devicePhotos(3);
    fakes.analysis.blocked.addAll({'p0', 'p2'});

    await pumpAnalyzing(tester);

    expect(find.text('Listo'), findsOneWidget);
    expect(
      find.text(
        'Tus fotos ya están en Memory Lens. 2 no se pudieron analizar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('when it is over it says «Listo» and leads to Recuerdos', (
    tester,
  ) async {
    fakes.gallery.photos = devicePhotos(3);

    await pumpAnalyzing(tester);

    expect(find.text('Listo'), findsOneWidget);
    expect(
      find.text('Tus fotos ya están organizadas en Memory Lens.'),
      findsOneWidget,
    );
    expect(fakes.analysis.done.keys.toSet(), {'p0', 'p1', 'p2'});
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Ver recuerdos'));
    await settle(tester);

    expect(find.text('Pantalla Recuerdos'), findsOneWidget);
    expect(find.byType(AnalyzingScreen), findsNothing);
  });
}

/// Lets the bloc work and the screen change. It cannot use pumpAndSettle
/// because the spinner of the working states never stops.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
