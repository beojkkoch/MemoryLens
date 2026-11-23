import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Deletes a conversation of the account. Its photos stay (HU-24, CA8).
class DeleteConversationUseCase {
  final ChatRepository _chat = sl();

  Future<void> call(String conversationId) {
    return _chat.deleteConversation(conversationId);
  }
}
