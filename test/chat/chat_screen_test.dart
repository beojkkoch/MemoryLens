import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_bloc.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_event.dart';
import 'package:memorylens/features/chat/ui/screens/chat_screen.dart';
import 'package:memorylens/features/chat/ui/widgets/chat_input_bar.dart';
import 'package:memorylens/features/chat/ui/widgets/message_bubble.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/injection_container.dart';
import 'package:memorylens/theme/app_theme.dart';

import 'chat_test_setup.dart';
import 'fake_chat_repository.dart';
import 'fake_photo_search_repository.dart';

void main() {
  late FakeChatRepository chat;
  late FakePhotoSearchRepository search;

  const savedId = '0b4f6c1e-3a52-4f0a-9d7e-2c8b9a1d5e60';

  setUp(() async {
    (chat, search) = await setUpChat();
  });

  /// Opens the chat on top of a home, like Recuerdos does.
  Future<void> openChat(WidgetTester tester, {String? id}) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        routes: {
          '/': (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/chat', arguments: id),
              child: const Text('Inicio'),
            ),
          ),
          '/chat': (context) {
            final conversationId =
                ModalRoute.of(context)!.settings.arguments as String?;
            return BlocProvider(
              create: (_) => sl<ChatBloc>()..add(ChatStarted(conversationId)),
              child: ChatScreen(conversationId: conversationId),
            );
          },
          '/foto': (context) => Scaffold(
            body: Text('Detalle ${ModalRoute.of(context)!.settings.arguments}'),
          ),
        },
      ),
    );
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(ChatInputBar.fieldKey), text);
    await tester.pump();
    await tester.tap(find.byKey(ChatInputBar.sendKey));
    await tester.pump();
    await tester.pump();
  }

  /// A text inside a message, not the one in the app bar, which takes the
  /// name of the first question.
  Finder inBubble(String text) {
    return find.descendant(
      of: find.byType(MessageBubble),
      matching: find.text(text),
    );
  }

  IconButton sendButton(WidgetTester tester) {
    return tester.widget<IconButton>(find.byKey(ChatInputBar.sendKey));
  }

  String fieldText(WidgetTester tester) {
    return tester
        .widget<TextField>(find.byKey(ChatInputBar.fieldKey))
        .controller!
        .text;
  }

  group('the question field (HU-20)', () {
    testWidgets('has «Busca una foto…» and a send button (CA1)', (
      tester,
    ) async {
      await openChat(tester);

      expect(find.text('Busca una foto…'), findsOneWidget);
      expect(find.byKey(ChatInputBar.sendKey), findsOneWidget);
      expect(find.byTooltip('Enviar'), findsOneWidget);
    });

    testWidgets('the cursor is in the field when the chat opens (CA6)', (
      tester,
    ) async {
      await openChat(tester);

      final field = tester.widget<TextField>(find.byKey(ChatInputBar.fieldKey));
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('the button sends the question and clears the field (CA2)', (
      tester,
    ) async {
      await openChat(tester);

      await ask(tester, 'factura del café');

      expect(search.asked, ['factura del café']);
      expect(fieldText(tester), isEmpty);
      expect(inBubble('factura del café'), findsOneWidget);
    });

    testWidgets('Enter sends it too, and the field keeps the cursor (CA2)', (
      tester,
    ) async {
      await openChat(tester);

      await tester.enterText(find.byKey(ChatInputBar.fieldKey), 'perros');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump();

      expect(search.asked, ['perros']);
      expect(fieldText(tester), isEmpty);
      final field = tester.widget<TextField>(find.byKey(ChatInputBar.fieldKey));
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('empty text, or only spaces, is not sent (CA3)', (
      tester,
    ) async {
      await openChat(tester);
      expect(sendButton(tester).onPressed, isNull);

      await tester.enterText(find.byKey(ChatInputBar.fieldKey), '    ');
      await tester.pump();
      expect(sendButton(tester).onPressed, isNull);

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(search.asked, isEmpty);
      expect(find.byType(MessageBubble), findsNothing);
    });

    testWidgets('the question is on the right with the main color (CA4)', (
      tester,
    ) async {
      await openChat(tester);

      await ask(tester, 'factura');

      final bubble = find
          .descendant(
            of: find.byType(MessageBubble).first,
            matching: find.byType(Container),
          )
          .first;
      final decoration =
          tester.widget<Container>(bubble).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.primary);
      final rect = tester.getRect(bubble);
      expect(rect.right, closeTo(430 - 16, 1));
      expect(rect.left, greaterThan(430 / 2 - 100));
    });
  });

  group('«Pensando…» (HU-20)', () {
    testWidgets('shows after sending, blocks the button and goes when the '
        'answer arrives (CA5, CA7, CA8)', (tester) async {
      search.gate = Completer<void>();
      await openChat(tester);
      expect(find.text('Pensando…'), findsNothing);

      await ask(tester, 'factura');

      expect(find.text('Pensando…'), findsOneWidget);
      // Typing a new question is possible, sending it is not.
      await tester.enterText(find.byKey(ChatInputBar.fieldKey), 'otra');
      await tester.pump();
      expect(sendButton(tester).onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(search.asked, ['factura']);

      search.gate!.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Pensando…'), findsNothing);
      expect(sendButton(tester).onPressed, isNotNull);
    });

    testWidgets('goes away too when the search fails, which says why (CA8)', (
      tester,
    ) async {
      search.error = const AppException('No pudimos conectarnos.');
      await openChat(tester);

      await ask(tester, 'factura');
      await tester.pump();

      expect(find.text('Pensando…'), findsNothing);
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);
      expect(inBubble('factura'), findsOneWidget);
    });

    testWidgets('a screen reader hears it as a live region', (tester) async {
      search.gate = Completer<void>();
      await openChat(tester);
      await ask(tester, 'factura');

      expect(
        tester.getSemantics(find.text('Pensando…')),
        isSemantics(isLiveRegion: true),
      );
    });
  });

  group('the answer and its photos', () {
    testWidgets('shows on the left with a grid of 3 columns that opens the '
        'photo', (tester) async {
      search.photos = [
        searchPhoto('p1', 'Factura del café'),
        searchPhoto('p2', 'Café con leche'),
        searchPhoto('p3', 'Montaña'),
        searchPhoto('p4', 'Mar'),
      ];
      await openChat(tester);

      await ask(tester, 'café');

      expect(find.text('Aquí tienes las coincidencias:'), findsOneWidget);
      final first = tester.getTopLeft(
        find.bySemanticsLabel('Abrir Factura del café'),
      );
      final second = tester.getTopLeft(
        find.bySemanticsLabel('Abrir Café con leche'),
      );
      final third = tester.getTopLeft(find.bySemanticsLabel('Abrir Montaña'));
      final fourth = tester.getTopLeft(find.bySemanticsLabel('Abrir Mar'));
      expect(second.dy, first.dy);
      expect(third.dy, first.dy);
      expect(fourth.dy, greaterThan(first.dy));
      expect(fourth.dx, first.dx);
      expect(
        tester.getSize(find.bySemanticsLabel('Abrir Mar')).aspectRatio,
        closeTo(1, 0.01),
      );
      final answer = tester.getRect(find.byType(MessageBubble).last);
      expect(answer.left, 16);

      await tester.tap(find.bySemanticsLabel('Abrir Montaña'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle p3'), findsOneWidget);
    });

    testWidgets('a photo whose file is gone says «Foto no disponible» '
        '(HU-25, CA5)', (tester) async {
      chat.seed(savedId, 'Café', [
        ChatMessage.question('café'),
        ChatMessage.answer(
          'Aquí tienes las coincidencias:',
          photos: [const MemoryPhoto(id: 'gone')],
        ),
      ]);
      await openChat(tester, id: savedId);

      expect(find.text('Foto no disponible'), findsOneWidget);
    });

    testWidgets('with no match there are no photos', (tester) async {
      await openChat(tester);

      await ask(tester, 'unicornios');

      expect(find.text('No encontré fotos que coincidan'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });
  });

  group('keeping it in the account (HU-25)', () {
    testWidgets('a conversation opens again with its messages and photos', (
      tester,
    ) async {
      chat.seed(savedId, 'Café', [
        ChatMessage.question('café'),
        ChatMessage.answer(
          'Aquí tienes las coincidencias:',
          photos: [searchPhoto('p1', 'Factura del café')],
        ),
      ]);

      await openChat(tester, id: savedId);

      expect(find.text('café'), findsOneWidget);
      expect(find.text('Aquí tienes las coincidencias:'), findsOneWidget);
      expect(find.bySemanticsLabel('Abrir Factura del café'), findsOneWidget);
    });

    testWidgets('a message that cannot be saved is told and can be tried '
        'again (CA4)', (tester) async {
      chat.saveError = const AppException('No pudimos conectarnos.');
      await openChat(tester);

      await ask(tester, 'factura');
      await tester.pump();

      expect(find.text('No pudimos conectarnos.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      // The question stays on screen and the button waits.
      expect(find.text('factura'), findsOneWidget);
      expect(sendButton(tester).onPressed, isNull);

      chat.saveError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Reintentar'), findsNothing);
      expect(chat.saves, hasLength(2));
      expect(search.asked, ['factura']);
    });

    testWidgets('a conversation that does not load says why and tries again', (
      tester,
    ) async {
      chat.error = const AppException('No pudimos conectarnos.');
      await openChat(tester);

      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      chat.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byKey(ChatInputBar.fieldKey), findsOneWidget);
    });
  });

  group('a new conversation (HU-23)', () {
    testWidgets('«+» (Nueva conversación) opens an empty one titled «Nueva '
        'búsqueda» (CA1, CA2)', (tester) async {
      chat.seed(savedId, 'Factura del café', [
        ChatMessage.question('factura del café'),
        ChatMessage.answer('Aquí tienes las coincidencias:'),
      ]);
      await openChat(tester, id: savedId);
      expect(find.text('Factura del café'), findsOneWidget);
      expect(find.byType(MessageBubble), findsNWidgets(2));

      await tester.tap(find.byTooltip('Nueva conversación'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva búsqueda'), findsOneWidget);
      expect(find.text('Factura del café'), findsNothing);
      expect(find.byType(MessageBubble), findsNothing);
      expect(chat.savedMessages(savedId), hasLength(2));
    });

    testWidgets('the cursor is in the field of the new conversation', (
      tester,
    ) async {
      await openChat(tester);
      await ask(tester, 'hola');

      await tester.tap(find.byTooltip('Nueva conversación'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byKey(ChatInputBar.fieldKey));
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('«+» waits while the assistant answers', (tester) async {
      search.gate = Completer<void>();
      await openChat(tester);
      await ask(tester, 'factura');

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(button.onPressed, isNull);
    });
  });
}
