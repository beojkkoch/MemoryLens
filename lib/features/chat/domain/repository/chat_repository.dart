import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';

/// The conversations of the person, kept in their account so they show again
/// after closing the app or on another device (HU-25).
abstract class ChatRepository {
  /// The saved conversations, the one with the latest activity first
  /// (HU-24, CA2).
  Future<List<Conversation>> conversations();

  /// Every message of a conversation with the photos of its answers, oldest
  /// first. A conversation that is not saved yet has none.
  Future<List<ChatMessage>> messages(String conversationId);

  /// Saves a message with its photos. The conversation is created with its
  /// first message and takes [title]; later messages do not change it.
  Future<void> saveMessage(
    String conversationId,
    ChatMessage message, {
    String? title,
  });

  /// Deletes the conversation with its messages. The photos stay (HU-24,
  /// CA8).
  Future<void> deleteConversation(String conversationId);
}
