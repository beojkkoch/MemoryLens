import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/injection_container.dart';

/// The messages and photos of a conversation, to open it again (HU-24, CA3).
class GetChatMessagesUseCase {
  final ChatRepository _chat = sl();

  Future<List<ChatMessage>> call(String conversationId) {
    return _chat.messages(conversationId);
  }
}
