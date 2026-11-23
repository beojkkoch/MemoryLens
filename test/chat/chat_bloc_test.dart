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

  group('a new conversation (HU-23)', () {
    test('opens an empty one titled «Nueva búsqueda» with an address of its '
        'own (CA2)', () async {
      chat.seed(savedId, 'Factura del café', [ChatMessage.question('hola')]);
      final bloc = await open(savedId);

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();

      expect(bloc.state.conversation.title, 'Nueva búsqueda');
      expect(bloc.state.conversation.id, isNotEmpty);
      expect(bloc.state.conversation.id, isNot(savedId));
      expect(bloc.state.messages, isEmpty);
    });

    test('every one gets a different address', () async {
      final bloc = await open();
      final first = bloc.state.conversation.id;

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();
      final second = bloc.state.conversation.id;
      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();

      expect({first, second, bloc.state.conversation.id}, hasLength(3));
    });

    test('the conversation before is not touched (CA3)', () async {
      chat.seed(savedId, 'Factura del café', [ChatMessage.question('hola')]);
      final bloc = await open(savedId);

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();

      expect(chat.saves, isEmpty);
      expect(chat.deleted, isEmpty);
      expect(chat.savedMessages(savedId), hasLength(1));
      expect(bloc.state.conversations.single.title, 'Factura del café');
    });

    test('without a message it never reaches the history (CA4)', () async {
      chat.seed(savedId, 'Factura del café');
      final bloc = await open(savedId);

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();
      final empty = bloc.state.conversation.id;
      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();

      expect(chat.isSaved(empty), isFalse);
      expect([for (final c in bloc.state.conversations) c.id], [savedId]);
      expect((await chat.conversations()).map((c) => c.id), [savedId]);
    });

    test('its first message creates it and names it', () async {
      chat.seed(savedId, 'Factura del café', [ChatMessage.question('hola')]);
      final bloc = await open(savedId);
      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();
      final created = bloc.state.conversation.id;

      bloc.add(ChatQuestionSent('mis perros'));
      await pumpEventQueue();

      expect(chat.isSaved(created), isTrue);
      expect(bloc.state.conversation.title, 'mis perros');
      expect(
        [for (final c in bloc.state.conversations) c.id],
        [created, savedId],
      );
      // The old one still has only its own message.
      expect(chat.savedMessages(savedId), hasLength(1));
    });

    test('is not opened while an answer is on its way or a message waits '
        'to be saved', () async {
      search.gate = Completer<void>();
      final bloc = await open(savedId);
      bloc.add(ChatQuestionSent('primera'));
      await pumpEventQueue();

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();
      expect(bloc.state.conversation.id, savedId);
      expect(bloc.state.messages, hasLength(1));

      search.gate!.complete();
      chat.answerSaveError = const AppException('No pudimos conectarnos.');
      await pumpEventQueue();
      expect(bloc.state.pendingSave, isNotNull);

      bloc.add(ChatNewConversationRequested());
      await pumpEventQueue();
      expect(bloc.state.conversation.id, savedId);
      expect(bloc.state.pendingSave, isNotNull);
    });
  });

  group('the conversations of the panel (HU-24)', () {
    ChatMessage answerWithPhoto() {
      return ChatMessage.answer(
        'Aquí tienes las coincidencias:',
        photos: [searchPhoto('p1', 'Uno')],
      );
    }

    test('the list is the saved conversations, the latest activity first '
        '(CA2)', () async {
      chat.seed('a', 'Primera');
      chat.seed('b', 'Segunda');
      chat.seed('c', 'Tercera');
      final bloc = await open('a');

      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();

      expect(
        [for (final c in bloc.state.conversations) c.title],
        ['Tercera', 'Segunda', 'Primera'],
      );
    });

    test('talking in an old one moves it to the top (CA2)', () async {
      chat.seed('a', 'Primera');
      chat.seed('b', 'Segunda');
      final bloc = await open('a');

      bloc.add(ChatQuestionSent('otra pregunta'));
      await pumpEventQueue();
      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();

      expect([for (final c in bloc.state.conversations) c.id], ['a', 'b']);
    });

    test('a conversation made on another device shows after the refresh '
        '(HU-25, CA2)', () async {
      chat.seed('a', 'Primera');
      final bloc = await open('a');
      chat.seed('elsewhere', 'Desde el computador');

      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();

      expect(bloc.state.conversations.first.id, 'elsewhere');
    });

    test('a refresh that fails keeps the list and says why', () async {
      chat.seed('a', 'Primera');
      final bloc = await open('a');
      chat.error = const AppException('No pudimos conectarnos.');

      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();

      expect(bloc.state.status, ChatStatus.ready);
      expect(bloc.state.conversations, hasLength(1));
      expect(bloc.state.listError, 'No pudimos conectarnos.');

      chat.error = null;
      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();
      expect(bloc.state.listError, isNull);
    });

    test('opening one brings all its messages and photos (CA3)', () async {
      chat.seed('old', 'Factura del café', [
        ChatMessage.question('factura del café'),
        answerWithPhoto(),
      ]);
      chat.seed('new', 'Perros');
      final bloc = await open('new');

      bloc.add(ChatConversationOpened('old'));
      await pumpEventQueue();

      expect(bloc.state.status, ChatStatus.ready);
      expect(bloc.state.conversation.title, 'Factura del café');
      expect(bloc.state.messages, hasLength(2));
      expect(bloc.state.messages.last.photos.single.id, 'p1');
    });

    test('a conversation that fails to open can be tried again', () async {
      chat.seed('old', 'Factura del café', [ChatMessage.question('hola')]);
      chat.seed('new', 'Perros');
      final bloc = await open('new');
      chat.error = const AppException('No pudimos conectarnos.');

      bloc.add(ChatConversationOpened('old'));
      await pumpEventQueue();

      expect(bloc.state.status, ChatStatus.failure);
      expect(bloc.state.conversation.id, 'old');
      expect(bloc.state.errorMessage, 'No pudimos conectarnos.');

      chat.error = null;
      bloc.add(ChatStarted(bloc.state.conversation.id));
      await pumpEventQueue();
      expect(bloc.state.status, ChatStatus.ready);
      expect(bloc.state.messages, hasLength(1));
    });

    test('the open one, or an unknown one, is not opened again', () async {
      chat.seed('a', 'Primera', [ChatMessage.question('hola')]);
      final bloc = await open('a');
      final states = <ChatState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);

      bloc.add(ChatConversationOpened('a'));
      bloc.add(ChatConversationOpened('unknown'));
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test('nothing opens while an answer is on its way', () async {
      search.gate = Completer<void>();
      chat.seed('a', 'Primera');
      chat.seed('b', 'Segunda');
      final bloc = await open('a');
      bloc.add(ChatQuestionSent('hola'));
      await pumpEventQueue();

      bloc.add(ChatConversationOpened('b'));
      await pumpEventQueue();

      expect(bloc.state.conversation.id, 'a');
      expect(bloc.state.thinking, isTrue);
    });

    test('deleting one takes it out of the account and the list; the open '
        'one stays (CA6, CA8)', () async {
      chat.seed('a', 'Primera', [ChatMessage.question('hola')]);
      chat.seed('b', 'Segunda', [ChatMessage.question('adiós')]);
      final bloc = await open('b');

      bloc.add(ChatConversationDeleted('a'));
      await pumpEventQueue();

      expect(chat.deleted, ['a']);
      expect(chat.isSaved('a'), isFalse);
      expect([for (final c in bloc.state.conversations) c.id], ['b']);
      expect(bloc.state.conversation.id, 'b');
      expect(bloc.state.messages, hasLength(1));
    });

    test('deleting the open one opens the latest that is left (CA7)', () async {
      chat.seed('a', 'Primera', [ChatMessage.question('hola')]);
      chat.seed('b', 'Segunda', [ChatMessage.question('adiós')]);
      chat.seed('c', 'Tercera', [ChatMessage.question('buenas')]);
      final bloc = await open('c');

      bloc.add(ChatConversationDeleted('c'));
      await pumpEventQueue();

      expect(bloc.state.status, ChatStatus.ready);
      expect(bloc.state.conversation.id, 'b');
      expect(bloc.state.messages.single.text, 'adiós');
      expect([for (final c in bloc.state.conversations) c.id], ['b', 'a']);
    });

    test('deleting the only one opens an empty conversation (CA7)', () async {
      chat.seed('a', 'Primera', [ChatMessage.question('hola')]);
      final bloc = await open('a');

      bloc.add(ChatConversationDeleted('a'));
      await pumpEventQueue();

      expect(bloc.state.status, ChatStatus.ready);
      expect(bloc.state.conversation.title, 'Nueva búsqueda');
      expect(bloc.state.conversation.id, isNot('a'));
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.conversations, isEmpty);
    });

    test('a delete that fails says why and keeps everything', () async {
      chat.seed('a', 'Primera');
      chat.seed('b', 'Segunda');
      final bloc = await open('b');
      chat.deleteError = const AppException('No pudimos conectarnos.');

      bloc.add(ChatConversationDeleted('a'));
      await pumpEventQueue();

      expect(bloc.state.deleteError, 'No pudimos conectarnos.');
      expect(bloc.state.conversations, hasLength(2));
      expect(chat.isSaved('a'), isTrue);

      // The error is not carried to the next change.
      chat.deleteError = null;
      bloc.add(ChatConversationsRequested());
      await pumpEventQueue();
      expect(bloc.state.deleteError, isNull);
    });

    test('the open conversation is not deleted while an answer is on its '
        'way', () async {
      search.gate = Completer<void>();
      chat.seed('a', 'Primera');
      final bloc = await open('a');
      bloc.add(ChatQuestionSent('hola'));
      await pumpEventQueue();

      bloc.add(ChatConversationDeleted('a'));
      await pumpEventQueue();

      expect(chat.deleted, isEmpty);
    });
  });
}
