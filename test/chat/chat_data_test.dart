import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/chat/data/source/supabase_chat_data_source.dart';
import 'package:memorylens/features/chat/data/source/supabase_photo_search_data_source.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/usecases/answer_question_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/save_chat_message_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';

import 'chat_test_setup.dart';
import 'fake_chat_repository.dart';
import 'fake_photo_search_repository.dart';

void main() {
  group('the title of a conversation (HU-23, HU-24)', () {
    test('a conversation with no question is «Nueva búsqueda» (CA2)', () {
      expect(Conversation.draft('abc').title, 'Nueva búsqueda');
      expect(Conversation.titleFor('   '), 'Nueva búsqueda');
    });

    test('the first question names it, with the spaces collapsed', () {
      expect(
        Conversation.titleFor('  ¿dónde está   la factura\ndel café? '),
        '¿dónde está la factura del café?',
      );
    });

    test('a long question is cut with «…»', () {
      final title = Conversation.titleFor('a' * 100);
      expect(title, '${'a' * 40}…');
    });
  });

  group('the words of a question (provisional search)', () {
    test('«¿dónde está la factura del café?» gives factura and cafe', () {
      expect(
        SupabasePhotoSearchDataSource.termsFrom(
          '¿dónde está la factura del café?',
        ),
        ['factura', 'cafe'],
      );
    });

    test('has no accents, signs, short words or repeats', () {
      expect(
        SupabasePhotoSearchDataSource.termsFrom(
          'Montaña, montaña!! de la en el 12 año',
        ),
        ['montana', 'ano'],
      );
    });

    test('the filler of a question says nothing', () {
      expect(
        SupabasePhotoSearchDataSource.termsFrom(
          'muéstrame las fotos de mis perros',
        ),
        ['perros'],
      );
      expect(SupabasePhotoSearchDataSource.termsFrom('¿?  !'), isEmpty);
    });

    test('a long question keeps the first words only', () {
      final question = [for (var i = 0; i < 20; i++) 'palabra$i'].join(' ');
      expect(
        SupabasePhotoSearchDataSource.termsFrom(question),
        hasLength(SupabasePhotoSearchDataSource.maxTerms),
      );
    });
  });

  group('the rows of the account (HU-25)', () {
    test('a message goes to guardar_mensaje_chat with its photos in order', () {
      final answer = ChatMessage.answer(
        'Aquí tienes las coincidencias:',
        photos: [searchPhoto('p2', 'Dos'), searchPhoto('p1', 'Uno')],
      );

      final params = SupabaseChatDataSource.paramsFor('c1', answer);

      expect(params, {
        'p_conversacion_id': 'c1',
        'p_titulo': null,
        'p_rol': 'assistant',
        'p_texto': 'Aquí tienes las coincidencias:',
        'p_fotos': ['p2', 'p1'],
      });
    });

    test('a question carries the title of its conversation', () {
      final params = SupabaseChatDataSource.paramsFor(
        'c1',
        ChatMessage.question(' hola '),
        title: 'hola',
      );
      expect(params['p_rol'], 'user');
      expect(params['p_texto'], 'hola');
      expect(params['p_titulo'], 'hola');
      expect(params['p_fotos'], isEmpty);
    });

    test('a conversation row reads its title and last activity', () {
      final conversation = SupabaseChatDataSource.conversationFrom({
        'id': 'c1',
        'titulo': 'factura del café',
        'actualizada_en': '2024-06-14T15:27:00+00:00',
      });
      expect(conversation.id, 'c1');
      expect(conversation.title, 'factura del café');
      expect(
        conversation.updatedAt,
        DateTime.utc(2024, 6, 14, 15, 27).toLocal(),
      );
    });

    test('the photos of an answer come in the order they were saved', () {
      final row = {
        'id': 'm1',
        'rol': 'assistant',
        'texto': 'Aquí tienes las coincidencias:',
        'creado_en': '2024-06-14T15:27:00+00:00',
        'resultado_mensaje': [
          {'foto_id': 'p1', 'posicion': 1},
          {'foto_id': 'p2', 'posicion': 0},
        ],
      };
      final photos = {
        'p1': searchPhoto('p1', 'Uno'),
        'p2': searchPhoto('p2', 'Dos'),
      };

      final message = SupabaseChatDataSource.messageFrom(row, photos);

      expect(message.role, ChatRole.assistant);
      expect([for (final p in message.photos) p.id], ['p2', 'p1']);
    });

    test('a photo that is gone stays, with no link, instead of failing '
        '(CA5)', () {
      final message = SupabaseChatDataSource.messageFrom({
        'id': 'm1',
        'rol': 'assistant',
        'texto': 'Aquí tienes las coincidencias:',
        'creado_en': '2024-06-14T15:27:00+00:00',
        'resultado_mensaje': [
          {'foto_id': 'gone', 'posicion': 0},
        ],
      }, <String, MemoryPhoto>{});

      expect(message.photos.single.id, 'gone');
      expect(message.photos.single.thumbnailUrl, isNull);
    });

    test('a question has no photos', () {
      final message = SupabaseChatDataSource.messageFrom({
        'id': 'm1',
        'rol': 'user',
        'texto': 'hola',
        'creado_en': '2024-06-14T15:27:00+00:00',
        'resultado_mensaje': [],
      }, <String, MemoryPhoto>{});
      expect(message.isUser, isTrue);
      expect(message.photos, isEmpty);
    });
  });

  group('use cases', () {
    late FakeChatRepository chat;
    late FakePhotoSearchRepository search;

    setUp(() async {
      (chat, search) = await setUpChat();
    });

    test('the answer lists the photos found', () async {
      search.photos = [searchPhoto('p1', 'Uno')];

      final answer = await AnswerQuestionUseCase()('factura del café');

      expect(answer.isUser, isFalse);
      expect(answer.text, AnswerQuestionUseCase.foundText);
      expect(answer.photos.single.id, 'p1');
      expect(search.asked, ['factura del café']);
    });

    test('with no match it says so and shows no photos (HU-26, CA1)', () async {
      final answer = await AnswerQuestionUseCase()('unicornios');

      expect(answer.text, 'No encontré fotos que coincidan');
      expect(answer.photos, isEmpty);
    });

    test('an empty question is not searched (HU-20, CA3)', () async {
      await expectLater(
        AnswerQuestionUseCase()('   '),
        throwsA(isA<AppException>()),
      );
      expect(search.asked, isEmpty);
    });

    test('the first question names the conversation when saved', () async {
      await SaveChatMessageUseCase()(
        'c1',
        ChatMessage.question('factura del café'),
      );
      await SaveChatMessageUseCase()('c1', ChatMessage.answer('Aquí'));

      expect(chat.saves[0].$3, 'factura del café');
      expect(chat.saves[1].$3, isNull);
    });
  });
}
