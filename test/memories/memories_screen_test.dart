import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_analyzed_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/domain/usecases/get_memories_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/screens/memories_screen.dart';
import 'package:memorylens/features/memories/ui/widgets/memories_grid.dart';
import 'package:memorylens/features/photo_detail/ui/screens/photo_detail_screen.dart';
import 'package:memorylens/injection_container.dart';

import '../gallery_access/fake_gallery_permission_repository.dart';
import '../gallery_import/gallery_import_test_setup.dart';
import 'fake_photo_repository.dart';

void main() {
  late FakeGalleryPermissionRepository permission;
  late FakePhotoRepository photos;
  late GalleryImportFakes importFakes;

  const connectButton = 'Permitir acceso a la galería';
  const dialogTitle = 'Memory Lens quiere acceder a tus fotos';
  const dialogText = 'Se usarán para analizarlas y organizarlas por ti';
  const settingsButton = 'Abrir ajustes';
  const deniedMessage =
      'Sin acceso a tus fotos no hay recuerdos para analizar.';

  setUp(() async {
    await sl.reset();
    permission = FakeGalleryPermissionRepository();
    photos = FakePhotoRepository();
    sl.registerSingleton<GalleryPermissionRepository>(permission);
    sl.registerSingleton<PhotoRepository>(photos);
    sl.registerLazySingleton(() => RequestGalleryAccessUseCase());
    sl.registerLazySingleton(() => CheckGalleryAccessUseCase());
    sl.registerLazySingleton(() => OpenGallerySettingsUseCase());
    sl.registerLazySingleton(() => CountPhotosUseCase());
    sl.registerLazySingleton(() => GetMemoriesUseCase());
    sl.registerLazySingleton(() => CountAnalyzedPhotosUseCase());
    sl.registerFactory(() => MemoriesBloc());
    // Analizando imports the photos, and Recuerdos asks if an import is
    // pending, so both need the import fakes.
    importFakes = registerGalleryImportFakes();
  });

  Future<void> pumpMemories(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/recuerdos',
        routes: {
          '/recuerdos': (_) => BlocProvider(
            create: (_) => sl<MemoriesBloc>()..add(MemoriesStarted()),
            child: const MemoriesScreen(),
          ),
          '/analizando': (_) => analyzingRoute(),
          '/foto': (context) => PhotoDetailScreen(
            photo: ModalRoute.of(context)!.settings.arguments as MemoryPhoto,
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets the dialog close, the bloc answer and the screen change. It cannot
  /// use pumpAndSettle because Analizando can show a spinner that never stops.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Presses the main button and answers the app's own dialog.
  Future<void> connect(WidgetTester tester, {required String answer}) async {
    await tester.tap(find.text(connectButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(answer));
    await settle(tester);
  }

  group('empty gallery', () {
    testWidgets('shows «Sin conectar», «0 fotos» and the invitation', (
      tester,
    ) async {
      await pumpMemories(tester);

      expect(find.text('Recuerdos'), findsOneWidget);
      expect(find.text('Sin conectar'), findsOneWidget);
      expect(find.text('0 fotos'), findsOneWidget);
      expect(find.text('Aún no tienes recuerdos'), findsOneWidget);
      expect(
        find.text(
          'Conecta tu galería para que Memory Lens empiece a recordarlo todo '
          'por ti',
        ),
        findsOneWidget,
      );
      expect(find.text(connectButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('nothing is asked before the person presses the button', (
      tester,
    ) async {
      await pumpMemories(tester);

      expect(find.text(dialogTitle), findsNothing);
      expect(permission.requestCalls, 0);
      expect(permission.checkCalls, 0);
    });

    testWidgets('a person with photos does not see the empty gallery', (
      tester,
    ) async {
      photos.photoCount = 3;
      photos.analyzedPhotos = [
        memoryPhoto('a', takenAt: DateTime(2024, 6, 15)),
        memoryPhoto('b', takenAt: DateTime(2024, 6, 15)),
        memoryPhoto('c', takenAt: DateTime(2024, 6, 14)),
      ];

      await pumpMemories(tester);

      expect(find.text('Aún no tienes recuerdos'), findsNothing);
      expect(find.text(connectButton), findsNothing);
      expect(find.text('Sin conectar'), findsNothing);
      expect(find.text('3 fotos'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that recovers', (tester) async {
      photos.error = const AppException('No pudimos conectarnos.');
      await pumpMemories(tester);

      expect(find.text('No pudimos conectarnos.'), findsOneWidget);
      expect(find.text(connectButton), findsNothing);

      photos.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes recuerdos'), findsOneWidget);
    });
  });

  group('own dialog', () {
    testWidgets('explains what the photos are for and has two buttons', (
      tester,
    ) async {
      await pumpMemories(tester);

      await tester.tap(find.text(connectButton));
      await tester.pumpAndSettle();

      expect(find.text(dialogTitle), findsOneWidget);
      expect(find.text(dialogText), findsOneWidget);
      expect(find.text('No permitir'), findsOneWidget);
      expect(find.text('Permitir'), findsOneWidget);
      expect(permission.requestCalls, 0);
    });

    testWidgets('«No permitir» closes it and does not ask again', (
      tester,
    ) async {
      await pumpMemories(tester);

      await connect(tester, answer: 'No permitir');

      expect(find.text(dialogTitle), findsNothing);
      expect(find.text('Aún no tienes recuerdos'), findsOneWidget);
      expect(find.text(connectButton), findsOneWidget);
      expect(find.text(deniedMessage), findsNothing);
      expect(permission.requestCalls, 0);
    });

    testWidgets('closing it by tapping outside counts as «No permitir»', (
      tester,
    ) async {
      await pumpMemories(tester);
      await tester.tap(find.text(connectButton));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text(dialogTitle), findsNothing);
      expect(find.text(connectButton), findsOneWidget);
      expect(permission.requestCalls, 0);
    });

    testWidgets('after «No permitir» the button opens it again', (
      tester,
    ) async {
      await pumpMemories(tester);
      await connect(tester, answer: 'No permitir');

      await tester.tap(find.text(connectButton));
      await tester.pumpAndSettle();

      expect(find.text(dialogTitle), findsOneWidget);
    });
  });

  group('new photos (HU-11)', () {
    void connectedWith({required int onDevice}) {
      photos.photoCount = 2;
      permission.checkResult = GalleryPermissionStatus.granted;
      importFakes.gallery.photos = devicePhotos(onDevice);
      importFakes.photos.imported.addAll({'p0', 'p1'});
      importFakes.analysis.done['p0'] = PhotoAnalysisOutcome.analyzed;
      importFakes.analysis.done['p1'] = PhotoAnalysisOutcome.analyzed;
    }

    testWidgets('shows «N nuevas fotos analizadas. Revisar etiquetas»', (
      tester,
    ) async {
      connectedWith(onDevice: 5);

      await pumpMemories(tester);
      await settle(tester);

      expect(find.text('3 nuevas fotos analizadas.'), findsOneWidget);
      expect(find.text('Revisar etiquetas'), findsOneWidget);
      expect(find.byType(AnalyzingScreen), findsNothing);
    });

    testWidgets('the notice can be closed', (tester) async {
      connectedWith(onDevice: 3);
      await pumpMemories(tester);
      await settle(tester);
      expect(find.text('1 nueva foto analizada.'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar aviso'));
      await settle(tester);

      expect(find.text('1 nueva foto analizada.'), findsNothing);
    });

    testWidgets('without new photos there is no notice', (tester) async {
      connectedWith(onDevice: 2);

      await pumpMemories(tester);
      await settle(tester);

      expect(find.textContaining('analizada'), findsNothing);
      expect(find.text('Revisar etiquetas'), findsNothing);
    });
  });

  group('system permission', () {
    testWidgets('«Permitir» asks the device and opens Analizando', (
      tester,
    ) async {
      permission.requestResult = GalleryPermissionStatus.granted;
      await pumpMemories(tester);

      await connect(tester, answer: 'Permitir');

      expect(permission.requestCalls, 1);
      expect(find.byType(AnalyzingScreen), findsOneWidget);
      expect(find.text('Analizando'), findsOneWidget);
      expect(find.text('Aún no tienes recuerdos'), findsNothing);
    });

    testWidgets('a denial explains it and lets the person try again', (
      tester,
    ) async {
      permission.requestResult = GalleryPermissionStatus.denied;
      await pumpMemories(tester);

      await connect(tester, answer: 'Permitir');

      expect(find.text(deniedMessage), findsOneWidget);
      expect(find.text(settingsButton), findsNothing);
      expect(find.text(connectButton), findsOneWidget);
      expect(find.byType(AnalyzingScreen), findsNothing);

      permission.requestResult = GalleryPermissionStatus.granted;
      await connect(tester, answer: 'Permitir');
      expect(find.byType(AnalyzingScreen), findsOneWidget);
    });

    testWidgets('a blocked permission also offers «Abrir ajustes»', (
      tester,
    ) async {
      permission.requestResult = GalleryPermissionStatus.blocked;
      await pumpMemories(tester);

      await connect(tester, answer: 'Permitir');

      expect(find.text(deniedMessage), findsOneWidget);
      expect(find.text(settingsButton), findsOneWidget);
      expect(find.byType(AnalyzingScreen), findsNothing);

      await tester.tap(find.text(settingsButton));
      await tester.pumpAndSettle();
      expect(permission.openSettingsCalls, 1);
    });

    testWidgets('turning it on in the settings opens Analizando on return', (
      tester,
    ) async {
      permission.requestResult = GalleryPermissionStatus.blocked;
      await pumpMemories(tester);
      await connect(tester, answer: 'Permitir');

      permission.checkResult = GalleryPermissionStatus.granted;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);

      expect(find.byType(AnalyzingScreen), findsOneWidget);
    });

    testWidgets('an import left half done opens Analizando on its own', (
      tester,
    ) async {
      photos.photoCount = 2;
      importFakes.scans.pending = true;
      permission.checkResult = GalleryPermissionStatus.granted;

      await pumpMemories(tester);
      await settle(tester);

      expect(find.byType(AnalyzingScreen), findsOneWidget);
      // The person already agreed: no dialog, no system request.
      expect(find.text(dialogTitle), findsNothing);
      expect(permission.requestCalls, 0);
    });

    testWidgets('a plugin failure shows a friendly message', (tester) async {
      permission.error = StateError('PlatformException(secret)');
      await pumpMemories(tester);

      await connect(tester, answer: 'Permitir');

      expect(find.text(AppException.genericMessage), findsOneWidget);
      expect(find.textContaining('PlatformException'), findsNothing);
      expect(find.text(connectButton), findsOneWidget);
    });
  });

  group('timeline (HU-12)', () {
    /// A connected gallery whose analyzed photos are [analyzed].
    void connectedWith(List<MemoryPhoto> analyzed) {
      photos.photoCount = analyzed.length;
      photos.analyzedPhotos = analyzed;
    }

    testWidgets('groups the photos under their day, newest first', (
      tester,
    ) async {
      final now = DateTime.now();
      connectedWith([
        memoryPhoto('old', takenAt: DateTime(2024, 6, 15, 9)),
        memoryPhoto('today', takenAt: now),
        memoryPhoto(
          'yesterday',
          takenAt: now.subtract(const Duration(days: 1)),
        ),
      ]);

      await pumpMemories(tester);

      final today = tester.getTopLeft(find.text('Hoy')).dy;
      final yesterday = tester.getTopLeft(find.text('Ayer')).dy;
      final june = tester.getTopLeft(find.text('15 jun 2024')).dy;
      expect(today, lessThan(yesterday));
      expect(yesterday, lessThan(june));
      expect(find.byType(MemoryTile), findsNWidgets(3));
    });

    testWidgets('a grid of 3 square columns (CA1)', (tester) async {
      connectedWith([
        for (var i = 0; i < 4; i++)
          memoryPhoto('p$i', takenAt: DateTime(2024, 6, 15, 12 - i)),
      ]);

      await pumpMemories(tester);

      final tiles = find.byType(MemoryTile);
      final first = tester.getRect(tiles.at(0));
      final third = tester.getRect(tiles.at(2));
      final fourth = tester.getRect(tiles.at(3));
      expect(first.width, closeTo(first.height, 0.01));
      expect(third.top, first.top);
      expect(fourth.top, greaterThan(first.bottom));
    });

    testWidgets(
      'shows the month of the newest photo and the total (CA5, CA6)',
      (tester) async {
        connectedWith([
          memoryPhoto('a', takenAt: DateTime(2024, 5, 2)),
          memoryPhoto('b', takenAt: DateTime(2024, 6, 15)),
        ]);

        await pumpMemories(tester);

        expect(find.text('Junio 2024'), findsOneWidget);
        expect(find.text('2 fotos'), findsOneWidget);
      },
    );

    testWidgets('one photo says «1 foto» (CA6)', (tester) async {
      connectedWith([memoryPhoto('a', takenAt: DateTime(2024, 6, 15))]);

      await pumpMemories(tester);

      expect(find.text('1 foto'), findsOneWidget);
    });

    testWidgets('the total follows a finished analysis (CA6)', (tester) async {
      connectedWith([memoryPhoto('p0', takenAt: DateTime(2024, 6, 15))]);
      permission.checkResult = GalleryPermissionStatus.granted;
      importFakes.gallery.photos = devicePhotos(2);
      importFakes.photos.imported.add('p0');
      importFakes.analysis.done['p0'] = PhotoAnalysisOutcome.analyzed;
      // What the account has once the new photo is analyzed.
      photos.laterAnalyzed.add([
        memoryPhoto('p0', takenAt: DateTime(2024, 6, 15)),
        memoryPhoto('p1', takenAt: DateTime(2024, 6, 16)),
      ]);
      photos.recentIds.add('p1');

      await pumpMemories(tester);
      await settle(tester);

      expect(find.text('2 fotos'), findsOneWidget);
      expect(find.byType(MemoryTile), findsNWidgets(2));
    });

    testWidgets('every thumbnail reads «Abrir [título]» (CA8)', (tester) async {
      connectedWith([
        memoryPhoto('a', title: 'Café en el parque', takenAt: DateTime(2024)),
      ]);

      await pumpMemories(tester);

      expect(find.bySemanticsLabel('Abrir Café en el parque'), findsOneWidget);
    });

    testWidgets(
      'a tap opens the photo and the way back keeps the scroll (CA7)',
      (tester) async {
        connectedWith([
          for (var i = 0; i < 60; i++)
            memoryPhoto(
              'p$i',
              title: 'Foto $i',
              takenAt: DateTime(2024, 6, 1).subtract(Duration(days: i ~/ 3)),
            ),
        ]);
        await pumpMemories(tester);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
        final scrolled = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .pixels;
        expect(scrolled, greaterThan(0));

        final tile = find.byType(MemoryTile).hitTestable().first;
        final title = tester.widget<MemoryTile>(tile).photo.title!;
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(PhotoDetailScreen), findsOneWidget);
        expect(find.text(title), findsOneWidget);

        await tester.tap(find.byTooltip('Volver'));
        await tester.pumpAndSettle();
        expect(find.byType(PhotoDetailScreen), findsNothing);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .pixels,
          scrolled,
        );
      },
    );

    testWidgets('gray thumbnails while the photos load (CA9)', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => sl<MemoriesBloc>()..add(MemoriesStarted()),
            child: const MemoriesScreen(),
          ),
        ),
      );

      expect(find.byType(MemoriesGridPlaceholder), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(MemoriesGridPlaceholder), findsNothing);
    });

    testWidgets('with photos but none analyzed there is no empty grid (CA10)', (
      tester,
    ) async {
      photos.photoCount = 2;

      await pumpMemories(tester);

      expect(find.byType(MemoriesGrid), findsNothing);
      expect(find.text('Aún no tienes recuerdos'), findsOneWidget);
    });

    testWidgets('a thumbnail that does not load is a gray box (CA11)', (
      tester,
    ) async {
      connectedWith([
        memoryPhoto('missing', takenAt: DateTime(2024, 6, 15)),
        const MemoryPhoto(
          id: 'broken',
          title: 'Rota',
          thumbnailUrl: 'https://example.com/broken.jpg',
        ),
      ]);

      await pumpMemories(tester);

      // The test environment answers every request with an error.
      expect(find.byIcon(Icons.image_outlined), findsNWidgets(2));
      expect(find.byType(MemoryTile), findsNWidgets(2));
    });
  });

  group('more photos while scrolling (HU-15)', () {
    const pageSize = GetMemoriesUseCase.pageSize;

    setUp(() {
      photos.photoCount = 1000;
      photos.analyzedPhotos = manyPhotos(1000);
    });

    Future<void> scrollToEnd(WidgetTester tester) async {
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -5000),
        5000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets('the total counts every analyzed photo, not only the loaded '
        'ones', (tester) async {
      await pumpMemories(tester);

      expect(find.text('1000 fotos'), findsOneWidget);
      expect(photos.pageOffsets, [0]);
    });

    testWidgets('only the tiles close to the screen are built (CA4)', (
      tester,
    ) async {
      await pumpMemories(tester);

      expect(find.byType(MemoryTile).evaluate().length, lessThan(pageSize));
    });

    testWidgets('close to the end the next page loads with an indicator '
        '(CA2, CA3)', (tester) async {
      await pumpMemories(tester);
      photos.nextPageGate = Completer<void>();

      await scrollToEnd(tester);

      expect(find.bySemanticsLabel('Cargando más fotos'), findsOneWidget);
      expect(photos.pageOffsets, [0, pageSize]);

      photos.nextPageGate!.complete();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Cargando más fotos'), findsNothing);
      // The person can keep scrolling into the new page.
      await scrollToEnd(tester);
      await tester.pumpAndSettle();
      // The fling keeps going, page after page.
      expect(photos.pageOffsets.take(3), [0, pageSize, 2 * pageSize]);
    });
  });
}
