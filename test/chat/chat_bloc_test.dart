import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_bloc.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_event.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_state.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/injection_container.dart';

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

  /// Opens the chat and waits until it is ready.
  Future<ChatBloc> open([String? id]) async {
    final bloc = sl<ChatBloc>()..add(ChatStarted(id));
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((s) => s.status != ChatStatus.loading);
    return bloc;
  }

  group('opening the chat', () {
    test(
      'with no conversations it opens an empty one (HU-13 CA4, HU-23 CA2)',
      () async {
        final bloc = await open();

        expect(bloc.state.status, ChatStatus.ready);
        expect(bloc.state.conversation.title, 'Nueva búsqueda');
        expect(bloc.state.conversation.id, isNotEmpty);
        expect(bloc.state.messages, isEmpty);
      },
    );

    test('with conversations it opens the latest one with its messages '
        '(HU-13 CA4)', () async {
      chat.seed('older', 'Perros');
      chat.seed(savedId, 'Factura del café', [
        ChatMessage.question('factura del café'),
      ]);

      final bloc = await open();

      expect(bloc.state.conversation.id, savedId);
      expect(bloc.state.conversation.title, 'Factura del café');
      expect(
        [for (final m in bloc.state.messages) m.text],
        ['factura del café'],
      );
    });

    test('an address of a saved conversation opens that one', () async {
      chat.seed(savedId, 'Factura del café', [ChatMessage.question('hola')]);
      chat.seed('newer', 'Perros');

      final bloc = await open(savedId);

      expect(bloc.state.conversation.id, savedId);
      expect(bloc.state.messages, hasLength(1));
    });

    test('an address that is not saved yet is an empty conversation', () async {
      chat.seed('other', 'Perros');

      final bloc = await open(savedId);

      expect(bloc.state.conversation.id, savedId);
      expect(bloc.state.conversation.title, 'Nueva búsqueda');
      expect(bloc.state.messages, isEmpty);
    });

    test('a failed load says why and loads again with a new start', () async {
      chat.error = const AppException('No pudimos conectarnos.');
      final bloc = await open();
      expect(bloc.state.status, ChatStatus.failure);
      expect(bloc.state.errorMessage, 'No pudimos conectarnos.');

      chat.error = null;
      bloc.add(ChatStarted());
      await bloc.stream.firstWhere((s) => s.status == ChatStatus.ready);
    });
  });

  group('asking a question (HU-20)', () {
    test('the question shows at once and «Pensando…» lasts until the answer '
        '(CA4, CA7, CA8)', () async {
      search.gate = Completer<void>();
      search.photos = [searchPhoto('p1', 'Factura del café')];
      final bloc = await open();

      bloc.add(ChatQuestionSent('factura del café'));
      await pumpEventQueue();

      expect(bloc.state.thinking, isTrue);
      expect(
        [for (final m in bloc.state.messages) m.text],
        ['factura del café'],
      );
      expect(bloc.state.messages.single.isUser, isTrue);

      search.gate!.complete();
      await pumpEventQueue();

      expect(bloc.state.thinking, isFalse);
      expect(bloc.state.messages, hasLength(2));
      final answer = bloc.state.messages.last;
      expect(answer.isUser, isFalse);
      expect(answer.photos.single.id, 'p1');
    });

    test(
      'the question is trimmed and an empty one is not sent (CA3)',
      () async {
        final bloc = await open();

        bloc.add(ChatQuestionSent('   '));
        bloc.add(ChatQuestionSent(''));
        await pumpEventQueue();

        expect(bloc.state.messages, isEmpty);
        expect(search.asked, isEmpty);
        expect(chat.saves, isEmpty);

        bloc.add(ChatQuestionSent('  hola  '));
        await pumpEventQueue();
        expect(search.asked, ['hola']);
      },
    );

    test(
      'nothing else is sent while the answer is on its way (CA5, CA8)',
      () async {
        search.gate = Completer<void>();
        final bloc = await open();

        bloc.add(ChatQuestionSent('primera'));
        await pumpEventQueue();
        bloc.add(ChatQuestionSent('segunda'));
        await pumpEventQueue();

        expect(search.asked, ['primera']);
        expect(bloc.state.messages, hasLength(1));
      },
    );

    test('with no match the answer says so and shows no photos', () async {
      final bloc = await open();

      bloc.add(ChatQuestionSent('unicornios'));
      await pumpEventQueue();

      expect(bloc.state.messages.last.text, 'No encontré fotos que coincidan');
      expect(bloc.state.messages.last.photos, isEmpty);
    });

    test(
      'a failed search stops «Pensando…», says why and keeps the question',
      () async {
        search.error = const AppException('No pudimos conectarnos.');
        final bloc = await open();

        bloc.add(ChatQuestionSent('factura'));
        await pumpEventQueue();

        expect(bloc.state.thinking, isFalse);
        expect(bloc.state.answerError, 'No pudimos conectarnos.');
        expect([for (final m in bloc.state.messages) m.text], ['factura']);

        // The next question works and clears the error.
        search.error = null;
        bloc.add(ChatQuestionSent('factura otra vez'));
        await pumpEventQueue();
        expect(bloc.state.answerError, isNull);
        expect(bloc.state.messages, hasLength(3));
      },
    );
  });

  group('keeping the conversation in the account (HU-25)', () {
    test('the question and the answer with its photos are saved as they '
        'appear, in order (CA1)', () async {
      search.photos = [searchPhoto('p2', 'Dos'), searchPhoto('p1', 'Uno')];
      final bloc = await open(savedId);

      bloc.add(ChatQuestionSent('factura del café'));
      await pumpEventQueue();

      final saved = chat.savedMessages(savedId);
      expect(
        [for (final m in saved) m.role],
        [ChatRole.user, ChatRole.assistant],
      );
      expect(saved.first.text, 'factura del café');
      expect([for (final p in saved.last.photos) p.id], ['p2', 'p1']);
    });

    test('the first question names the conversation and it goes first in '
        'the list', () async {
      chat.seed('older', 'Perros');
      final bloc = await open(savedId);
      expect(chat.isSaved(savedId), isFalse);

      bloc.add(ChatQuestionSent('factura del café'));
      await pumpEventQueue();

      expect(chat.saves.first.$3, 'factura del café');
      expect(bloc.state.conversation.title, 'factura del café');
      expect(
        [for (final c in bloc.state.conversations) c.id],
        [savedId, 'older'],
      );
    });

    test('the title does not change with later questions', () async {
      final bloc = await open(savedId);

      bloc.add(ChatQuestionSent('primera'));
      await pumpEventQueue();
      bloc.add(ChatQuestionSent('segunda'));
      await pumpEventQueue();

      expect(bloc.state.conversation.title, 'primera');
    });

    test('a question that cannot be saved is kept and not answered; trying '
        'again saves it and answers (CA4)', () async {
      chat.saveError = const AppException('No pudimos conectarnos.');
      final bloc = await open(savedId);

      bloc.add(ChatQuestionSent('factura'));
      await pumpEventQueue();

      expect(bloc.state.thinking, isFalse);
      expect(bloc.state.saveError, 'No pudimos conectarnos.');
      expect(bloc.state.pendingSave?.text, 'factura');
      expect([for (final m in bloc.state.messages) m.text], ['factura']);
      expect(search.asked, isEmpty);

      chat.saveError = null;
      bloc.add(ChatSaveRetried());
      await pumpEventQueue();

      expect(bloc.state.pendingSave, isNull);
      expect(bloc.state.saveError, isNull);
      expect(search.asked, ['factura']);
      expect(chat.savedMessages(savedId), hasLength(2));
      expect(bloc.state.messages, hasLength(2));
    });

    test('an answer that cannot be saved still shows with its photos, and '
        'trying again saves only it (CA4)', () async {
      search.photos = [searchPhoto('p1', 'Uno')];
      chat.answerSaveError = const AppException('No pudimos conectarnos.');
      final bloc = await open(savedId);

      bloc.add(ChatQuestionSent('factura'));
      await pumpEventQueue();

      // The question is saved; the answer is on screen and waits.
      expect(chat.savedMessages(savedId).map((m) => m.text), ['factura']);
      expect(bloc.state.thinking, isFalse);
      expect(bloc.state.messages, hasLength(2));
      expect(bloc.state.pendingSave?.isUser, isFalse);
      expect(bloc.state.pendingSave?.photos.single.id, 'p1');
      expect(bloc.state.saveError, 'No pudimos conectarnos.');

      chat.answerSaveError = null;
      bloc.add(ChatSaveRetried());
      await pumpEventQueue();

      expect(bloc.state.pendingSave, isNull);
      expect(bloc.state.saveError, isNull);
      // It was not asked, nor the question saved, a second time.
      expect(search.asked, ['factura']);
      expect(chat.savedMessages(savedId), hasLength(2));
      expect(chat.savedMessages(savedId).last.photos.single.id, 'p1');
    });

    test('while a message waits to be saved nothing new is sent, so the '
        'order is kept', () async {
      chat.saveError = const AppException('No pudimos conectarnos.');
      final bloc = await open(savedId);
      bloc.add(ChatQuestionSent('primera'));
      await pumpEventQueue();

      bloc.add(ChatQuestionSent('segunda'));
      await pumpEventQueue();

      expect(bloc.state.messages, hasLength(1));
    });
  });
}
