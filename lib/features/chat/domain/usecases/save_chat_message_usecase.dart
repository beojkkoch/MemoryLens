import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Saves a question or an answer in the account as soon as it exists
/// (HU-25, CA1). The first question names the conversation.
class SaveChatMessageUseCase {
  final ChatRepository _chat = sl();

  Future<void> call(String conversationId, ChatMessage message) {
    return _chat.saveMessage(
      conversationId,
      message,
      title: message.isUser ? Conversation.titleFor(message.text) : null,
    );
  }
}
