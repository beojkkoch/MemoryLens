import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/features/chat/domain/repository/photo_search_repository.dart';
import 'package:memorylens/features/chat/domain/usecases/answer_question_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/delete_conversation_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/save_chat_message_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/start_conversation_usecase.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_bloc.dart';
import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_chat_repository.dart';
import 'fake_photo_search_repository.dart';

/// Registers the chat with fake repositories, the way main does with the real
/// ones. Returns them to set up each test.
Future<(FakeChatRepository, FakePhotoSearchRepository)> setUpChat() async {
  await sl.reset();
  final chat = FakeChatRepository();
  final search = FakePhotoSearchRepository();
  sl.registerSingleton<ChatRepository>(chat);
  sl.registerSingleton<PhotoSearchRepository>(search);
  sl.registerLazySingleton(() => GetConversationsUseCase());
  sl.registerLazySingleton(() => GetChatMessagesUseCase());
  sl.registerLazySingleton(() => StartConversationUseCase());
  sl.registerLazySingleton(() => SaveChatMessageUseCase());
  sl.registerLazySingleton(() => AnswerQuestionUseCase());
  sl.registerLazySingleton(() => DeleteConversationUseCase());
  sl.registerFactory(() => ChatBloc());
  return (chat, search);
}

/// A photo of the search, with a link to its thumbnail.
MemoryPhoto searchPhoto(String id, String title) {
  return MemoryPhoto(
    id: id,
    title: title,
    thumbnailUrl: 'https://example.com/thumbs/$id.jpg?token=1',
  );
}
