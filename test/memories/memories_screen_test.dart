import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/screens/memories_screen.dart';
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
}
