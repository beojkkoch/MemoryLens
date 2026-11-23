import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';

/// How the load of the conversation went.
enum ChatStatus { loading, ready, failure }

/// Marks a copyWith field that was not given, because null is a value for
/// the ones that can be cleared.
const Object _keep = Object();

/// Single state of the chat.
///
/// What the person is typing lives in the screen, not here, so a failure
/// never takes it away.
class ChatState {
  final ChatStatus status;

  /// The conversation that is open. An empty one until its first message.
  final Conversation conversation;
  final List<ChatMessage> messages;

  /// The saved conversations, the latest activity first.
  final List<Conversation> conversations;

  /// A question is being answered: «Pensando…» shows and nothing else can be
  /// sent (HU-20, CA5, CA7, CA8).
  final bool thinking;

  /// The message that could not be saved yet, kept to try again (HU-25, CA4).
  final ChatMessage? pendingSave;
  final String? saveError;

  /// Why the search failed, shown in the conversation.
  final String? answerError;

  /// Why the conversation could not be loaded.
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.loading,
    this.conversation = const Conversation(
      id: '',
      title: Conversation.defaultTitle,
    ),
    this.messages = const [],
    this.conversations = const [],
    this.thinking = false,
    this.pendingSave,
    this.saveError,
    this.answerError,
    this.errorMessage,
  });

  /// The pending message, its error and the search error are carried over
  /// unless given, and given as null they are cleared.
  ChatState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    List<Conversation>? conversations,
    bool? thinking,
    Object? pendingSave = _keep,
    Object? saveError = _keep,
    Object? answerError = _keep,
  }) {
    return ChatState(
      status: status,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      thinking: thinking ?? this.thinking,
      pendingSave: identical(pendingSave, _keep)
          ? this.pendingSave
          : pendingSave as ChatMessage?,
      saveError: identical(saveError, _keep)
          ? this.saveError
          : saveError as String?,
      answerError: identical(answerError, _keep)
          ? this.answerError
          : answerError as String?,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'ChatState(status: ${status.name}, conversation: $conversation, '
        'messages: ${messages.length}, thinking: $thinking, '
        'pendingSave: $pendingSave, saveError: $saveError, '
        'answerError: $answerError, error: $errorMessage)';
  }
}
