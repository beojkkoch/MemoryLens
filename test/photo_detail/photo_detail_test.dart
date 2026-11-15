import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/memories/ui/widgets/memory_dates.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/data/source/supabase_photo_detail_data_source.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_categories_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/get_photo_detail_usecase.dart';
import 'package:memorylens/features/photo_detail/domain/usecases/save_photo_edit_usecase.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_bloc.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_event.dart';
import 'package:memorylens/features/photo_detail/ui/bloc/photo_detail_state.dart';
import 'package:memorylens/features/photo_detail/ui/screens/photo_detail_screen.dart';
import 'package:memorylens/features/photo_detail/ui/widgets/photo_analysis_panel.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_photo_detail_repository.dart';

void main() {
  late FakePhotoDetailRepository photos;

  const invoiceId = '0b4f6c1e-3a52-4f0a-9d7e-2c8b9a1d5e60';
  final invoice = PhotoDetail(
    id: invoiceId,
    imageUrl: 'https://example.com/fotos/large.jpg?token=1',
    title: 'Café en Juan Valdez',
    description: 'Recibo de una cafetería con dos bebidas.',
    takenAt: DateTime(2024, 6, 14, 10, 27),
    category: 'Factura',
    purchaseType: 'Cafetería',
    total: const Money(amount: 23100, currency: 'COP'),
  );

  setUp(() async {
    await sl.reset();
    photos = FakePhotoDetailRepository();
    sl.registerSingleton<PhotoDetailRepository>(photos);
    sl.registerLazySingleton(() => GetPhotoDetailUseCase());
    sl.registerLazySingleton(() => GetCategoriesUseCase());
    sl.registerLazySingleton(() => SavePhotoEditUseCase());
    sl.registerFactory(() => PhotoDetailBloc());
  });

  group('a row of foto (HU-28)', () {
    test('reads every field and the category embedded', () {
      final detail = SupabasePhotoDetailDataSource.detailFrom({
        'id': invoiceId,
        'titulo': 'Café en Juan Valdez',
        'texto_alt': 'Recibo de una cafetería.',
        'fecha_captura': '2024-06-14T15:27:00+00:00',
        'tipo_compra': 'Cafetería',
        'monto': 23.1,
        'moneda': 'USD',
        'categoria': {'nombre': 'Factura'},
      }, imageUrl: 'https://example.com/large.jpg');

      expect(detail.imageUrl, 'https://example.com/large.jpg');
      expect(detail.title, 'Café en Juan Valdez');
      expect(detail.description, 'Recibo de una cafetería.');
      expect(detail.takenAt, DateTime.utc(2024, 6, 14, 15, 27).toLocal());
      expect(detail.category, 'Factura');
      expect(detail.purchaseType, 'Cafetería');
      expect(detail.total, const Money(amount: 23.1, currency: 'USD'));
    });

    test('what is not there stays empty', () {
      final detail = SupabasePhotoDetailDataSource.detailFrom({
        'id': invoiceId,
        'titulo': '  ',
        'texto_alt': null,
        'fecha_captura': null,
        'tipo_compra': null,
        'monto': null,
        'moneda': null,
        'categoria': null,
      });

      expect(detail.title, isNull);
      expect(detail.takenAt, isNull);
      expect(detail.category, isNull);
      expect(detail.purchaseType, isNull);
      expect(detail.total, isNull);
    });
  });

  test('the date reads «14 jun 2024, 10:27» (CA7)', () {
    expect(
      MemoryDates.dateTimeLabel(DateTime(2024, 6, 14, 10, 27)),
      '14 jun 2024, 10:27',
    );
    expect(
      MemoryDates.dateTimeLabel(DateTime(2023, 1, 5, 9, 5)),
      '5 ene 2023, 09:05',
    );
  });

  group('the bloc', () {
    test('a photo of the person is ready', () async {
      photos.details[invoiceId] = invoice;
      final bloc = PhotoDetailBloc()..add(PhotoDetailRequested(invoiceId));
      addTearDown(bloc.close);

      final state = await bloc.stream.firstWhere(
        (s) => s.status != PhotoDetailStatus.loading,
      );

      expect(state.status, PhotoDetailStatus.ready);
      expect(state.detail, invoice);
    });

    test('a missing or foreign photo is not found (CA5)', () async {
      final bloc = PhotoDetailBloc()..add(PhotoDetailRequested('other'));
      addTearDown(bloc.close);

      final state = await bloc.stream.firstWhere(
        (s) => s.status != PhotoDetailStatus.loading,
      );

      expect(state.status, PhotoDetailStatus.notFound);
    });

    test('a failed load shows the reason', () async {
      photos.error = const AppException('No pudimos conectarnos.');
      final bloc = PhotoDetailBloc()..add(PhotoDetailRequested(invoiceId));
      addTearDown(bloc.close);

      final state = await bloc.stream.firstWhere(
        (s) => s.status != PhotoDetailStatus.loading,
      );

      expect(state.status, PhotoDetailStatus.failure);
      expect(state.errorMessage, 'No pudimos conectarnos.');
    });
  });

  group('the screen', () {
    /// What a text field of the panel holds.
    String fieldText(WidgetTester tester, Key key) {
      return tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
    }

    /// Opens the detail of [photoId] on top of a first screen, the way
    /// Recuerdos does.
    Future<void> openDetail(WidgetTester tester, String photoId) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/foto', arguments: photoId),
                child: const Text('Inicio'),
              ),
            ),
            '/recuerdos': (_) => const Scaffold(body: Text('Recuerdos')),
            '/foto': (context) {
              final id = ModalRoute.of(context)!.settings.arguments as String;
              return BlocProvider(
                create: (_) =>
                    sl<PhotoDetailBloc>()..add(PhotoDetailRequested(id)),
                child: PhotoDetailScreen(photoId: id),
              );
            },
          },
        ),
      );
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the analysis and the four fields (CA2, CA6, CA7)', (
      tester,
    ) async {
      photos.details[invoiceId] = invoice;

      await openDetail(tester, invoiceId);

      expect(find.text('ANÁLISIS DE IA'), findsOneWidget);
      expect(find.text('Café en Juan Valdez'), findsOneWidget);
      expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
      expect(
        find.text('Recibo de una cafetería con dos bebidas.'),
        findsOneWidget,
      );
      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('14 jun 2024, 10:27'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Factura'), findsOneWidget);
      expect(find.text('Tipo de compra'), findsOneWidget);
      expect(
        fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey),
        'Cafetería',
      );
      expect(find.text('Monto total'), findsOneWidget);
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '23100');
      // The date is plain text, not a field.
      expect(
        find.ancestor(
          of: find.text('14 jun 2024, 10:27'),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
    });

    testWidgets('the fields go in two columns (CA6)', (tester) async {
      photos.details[invoiceId] = invoice;

      await openDetail(tester, invoiceId);

      final date = tester.getTopLeft(find.text('Fecha'));
      final category = tester.getTopLeft(find.text('Categoría'));
      final type = tester.getTopLeft(find.text('Tipo de compra'));
      final total = tester.getTopLeft(find.text('Monto total'));
      expect(category.dy, date.dy);
      expect(category.dx, greaterThan(date.dx));
      expect(type.dx, date.dx);
      expect(type.dy, greaterThan(date.dy));
      expect(total.dy, type.dy);
    });

    testWidgets('the photo takes about 70 % of the screen and is the large '
        'copy (CA1, CA4)', (tester) async {
      photos.details[invoiceId] = invoice;

      await openDetail(tester, invoiceId);

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, invoice.imageUrl);
      expect(tester.getSize(find.byType(Image)).height, closeTo(900 * 0.7, 1));
    });

    testWidgets('a missing value shows «—» (CA8)', (tester) async {
      photos.details[invoiceId] = const PhotoDetail(
        id: invoiceId,
        title: 'Recibo borroso',
        category: 'Factura',
      );

      await openDetail(tester, invoiceId);

      expect(find.text('Factura'), findsOneWidget);
      // The date shows «—», and the empty fields have it as their hint.
      expect(find.text('—'), findsWidgets);
      expect(fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey), '');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '');
    });

    testWidgets('a photo that is not an invoice has no purchase fields '
        '(HU-29, CA1)', (tester) async {
      photos.details[invoiceId] = const PhotoDetail(
        id: invoiceId,
        title: 'Atardecer',
        category: 'Lugar',
      );

      await openDetail(tester, invoiceId);

      expect(find.text('Lugar'), findsOneWidget);
      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('Tipo de compra'), findsNothing);
      expect(find.text('Monto total'), findsNothing);
    });

    testWidgets('neither does one with no category (HU-29, CA1)', (
      tester,
    ) async {
      photos.details[invoiceId] = const PhotoDetail(id: invoiceId);

      await openDetail(tester, invoiceId);

      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Tipo de compra'), findsNothing);
      expect(find.text('Monto total'), findsNothing);
    });

    testWidgets('the back button goes back to the screen before (CA3)', (
      tester,
    ) async {
      photos.details[invoiceId] = invoice;
      await openDetail(tester, invoiceId);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoDetailScreen), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('a photo that is not the person\'s says so and goes back '
        '(CA5)', (tester) async {
      await openDetail(tester, 'not-mine');

      expect(find.text('Foto no encontrada'), findsOneWidget);
      expect(find.text('ANÁLISIS DE IA'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Volver'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that recovers', (tester) async {
      photos.error = const AppException('No pudimos conectarnos.');
      await openDetail(tester, invoiceId);
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      photos.error = null;
      photos.details[invoiceId] = invoice;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Café en Juan Valdez'), findsOneWidget);
    });
  });

  group('correcting the data (HU-30)', () {
    Future<void> openDetail(WidgetTester tester, String photoId) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/foto', arguments: photoId),
                child: const Text('Inicio'),
              ),
            ),
            '/recuerdos': (_) => const Scaffold(body: Text('Recuerdos')),
            '/foto': (context) {
              final id = ModalRoute.of(context)!.settings.arguments as String;
              return BlocProvider(
                create: (_) =>
                    sl<PhotoDetailBloc>()..add(PhotoDetailRequested(id)),
                child: PhotoDetailScreen(photoId: id),
              );
            },
          },
        ),
      );
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester, Key key) {
      return tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
    }

    Future<void> pressDone(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Hecho'));
      await tester.tap(find.text('Hecho'));
      await tester.pump();
    }

    Future<void> chooseCategory(WidgetTester tester, String name) async {
      await tester.ensureVisible(find.byKey(PhotoAnalysisPanel.categoryKey));
      await tester.tap(find.byKey(PhotoAnalysisPanel.categoryKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    testWidgets('purchase type and total of an invoice can be changed and '
        'saved; then the home opens (CA1, CA7)', (tester) async {
      photos.details[invoiceId] = invoice;
      await openDetail(tester, invoiceId);

      await tester.enterText(
        find.byKey(PhotoAnalysisPanel.purchaseTypeKey),
        'Restaurante',
      );
      await tester.enterText(find.byKey(PhotoAnalysisPanel.amountKey), '45000');
      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(photos.saved.single.$1, invoiceId);
      expect(
        photos.saved.single.$2,
        const PhotoEdit(
          category: 'Factura',
          purchaseType: 'Restaurante',
          total: Money(amount: 45000, currency: 'COP'),
        ),
      );
      expect(find.text('Recuerdos'), findsOneWidget);
      expect(find.byType(PhotoDetailScreen), findsNothing);
    });

    testWidgets('the amount shows its currency and takes up to 2 decimals '
        '(CA2)', (tester) async {
      photos.details[invoiceId] = const PhotoDetail(
        id: invoiceId,
        category: 'Factura',
        total: Money(amount: 23.1, currency: 'USD'),
      );
      await openDetail(tester, invoiceId);
      final amount = find.byKey(PhotoAnalysisPanel.amountKey);

      expect(find.text(r'$ '), findsOneWidget);
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '23.10');

      await tester.enterText(amount, '12,5');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '12,5');
      await tester.enterText(amount, '12.345');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '12,5');
      await tester.enterText(amount, '12a');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '12,5');

      await pressDone(tester);
      await tester.pumpAndSettle();
      expect(
        photos.saved.single.$2.total,
        const Money(amount: 12.5, currency: 'USD'),
      );
    });

    testWidgets('a negative amount cannot be typed, nor saved as 0 (CA3)', (
      tester,
    ) async {
      photos.details[invoiceId] = invoice;
      await openDetail(tester, invoiceId);
      final amount = find.byKey(PhotoAnalysisPanel.amountKey);

      await tester.enterText(amount, '-500');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '23100');

      await tester.enterText(amount, '0');
      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(SavePhotoEditUseCase.invalidAmountMessage),
        findsOneWidget,
      );
      expect(photos.saved, isEmpty);
    });

    testWidgets('the category offers the catalog and is saved (CA5)', (
      tester,
    ) async {
      photos.details[invoiceId] = const PhotoDetail(
        id: invoiceId,
        title: 'Perro',
        category: 'Personas',
      );
      await openDetail(tester, invoiceId);

      await tester.tap(find.byKey(PhotoAnalysisPanel.categoryKey));
      await tester.pumpAndSettle();
      for (final name in photos.categoryNames) {
        expect(find.text(name), findsWidgets);
      }
      await tester.tap(find.text('Mascotas').last);
      await tester.pumpAndSettle();
      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(photos.saved.single.$2, const PhotoEdit(category: 'Mascotas'));
    });

    testWidgets('an empty category is not accepted (CA5)', (tester) async {
      photos.details[invoiceId] = const PhotoDetail(id: invoiceId);
      await openDetail(tester, invoiceId);

      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(SavePhotoEditUseCase.missingCategoryMessage),
        findsOneWidget,
      );
      expect(photos.saved, isEmpty);
    });

    testWidgets('moving a photo to «Factura» shows the purchase fields empty '
        '(HU-29, CA2)', (tester) async {
      photos.details[invoiceId] = const PhotoDetail(
        id: invoiceId,
        category: 'Lugar',
      );
      await openDetail(tester, invoiceId);
      expect(find.byKey(PhotoAnalysisPanel.amountKey), findsNothing);

      await chooseCategory(tester, 'Factura');

      expect(fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey), '');
      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '');
    });

    testWidgets('another category hides the purchase data and saving clears '
        'it (HU-29, CA3)', (tester) async {
      photos.details[invoiceId] = invoice;
      await openDetail(tester, invoiceId);

      await chooseCategory(tester, 'Comida');
      expect(find.byKey(PhotoAnalysisPanel.purchaseTypeKey), findsNothing);
      // Back to «Factura» before saving: nothing was lost.
      await chooseCategory(tester, 'Factura');
      expect(
        fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey),
        'Cafetería',
      );

      await chooseCategory(tester, 'Comida');
      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(photos.saved.single.$2, const PhotoEdit(category: 'Comida'));
    });

    testWidgets('the button shows it is saving (CA8)', (tester) async {
      photos.details[invoiceId] = invoice;
      photos.saveGate = Completer<void>();
      await openDetail(tester, invoiceId);

      await pressDone(tester);

      expect(find.text('Hecho'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PhotoAnalysisPanel),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      photos.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Recuerdos'), findsOneWidget);
    });

    testWidgets('a failed save says so and keeps the changes (CA8)', (
      tester,
    ) async {
      photos.details[invoiceId] = invoice;
      photos.saveError = const AppException('No pudimos conectarnos.');
      await openDetail(tester, invoiceId);

      await tester.enterText(
        find.byKey(PhotoAnalysisPanel.purchaseTypeKey),
        'Restaurante',
      );
      await pressDone(tester);
      await tester.pumpAndSettle();

      expect(find.text('No pudimos conectarnos.'), findsOneWidget);
      expect(find.byType(PhotoDetailScreen), findsOneWidget);
      expect(
        fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey),
        'Restaurante',
      );

      photos.saveError = null;
      await pressDone(tester);
      await tester.pumpAndSettle();
      expect(photos.saved.single.$2.purchaseType, 'Restaurante');
    });

    testWidgets('opening the photo again shows what was saved (CA9)', (
      tester,
    ) async {
      photos.details[invoiceId] = invoice;
      await openDetail(tester, invoiceId);
      await tester.enterText(find.byKey(PhotoAnalysisPanel.amountKey), '9900');
      await pressDone(tester);
      await tester.pumpAndSettle();

      // A fresh app, as when the person opens the photo another day.
      await tester.pumpWidget(const SizedBox());
      await openDetail(tester, invoiceId);

      expect(fieldText(tester, PhotoAnalysisPanel.amountKey), '9900');
      expect(
        fieldText(tester, PhotoAnalysisPanel.purchaseTypeKey),
        'Cafetería',
      );
    });
  });

  group('saving the corrections (HU-30)', () {
    test('outside «Factura» the purchase data is not sent', () async {
      await SavePhotoEditUseCase()(
        invoiceId,
        const PhotoEdit(
          category: 'Comida',
          purchaseType: 'Cafetería',
          total: Money(amount: 10, currency: 'COP'),
        ),
      );

      expect(photos.saved.single.$2, const PhotoEdit(category: 'Comida'));
    });

    test('an empty category or a non positive amount is not saved', () async {
      expect(
        () => SavePhotoEditUseCase()(invoiceId, const PhotoEdit(category: ' ')),
        throwsA(isA<AppException>()),
      );
      expect(
        () => SavePhotoEditUseCase()(
          invoiceId,
          const PhotoEdit(
            category: 'Factura',
            total: Money(amount: -1, currency: 'COP'),
          ),
        ),
        throwsA(isA<AppException>()),
      );
      expect(photos.saved, isEmpty);
    });

    test('the parameters of guardar_correccion_foto', () {
      expect(
        SupabasePhotoDetailDataSource.paramsFor(
          invoiceId,
          const PhotoEdit(
            category: 'Factura',
            purchaseType: 'Cafetería',
            total: Money(amount: 23.1, currency: 'USD'),
          ),
        ),
        {
          'p_foto_id': invoiceId,
          'p_categoria': 'Factura',
          'p_tipo_compra': 'Cafetería',
          'p_monto': 23.1,
          'p_moneda': 'USD',
        },
      );
    });

    test('the amount pattern takes up to 2 decimals and no sign', () {
      final pattern = PhotoAnalysisPanel.amountPattern;
      for (final ok in ['', '0', '23100', '23.1', '23,10', '23.']) {
        expect(pattern.hasMatch(ok), isTrue, reason: ok);
      }
      for (final bad in ['-1', '1.234', '1e5', 'abc', '1.2.3', '12345678901']) {
        expect(pattern.hasMatch(bad), isFalse, reason: bad);
      }
    });
  });
}
