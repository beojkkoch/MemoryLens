import 'package:memorylens/features/memories/domain/entities/memory_photo.dart';
import 'package:uuid/uuid.dart';

enum ChatRole { user, assistant }

/// A message of a conversation: what the person asked, or what the assistant
/// answered with the photos it found.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  /// The photos the answer shows, in order. Empty for a question.
  final List<MemoryPhoto> photos;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.photos = const [],
  });

  /// A question of the person, with the spaces of the ends removed. The id
  /// only tells the messages apart on screen; the account gives its own.
  factory ChatMessage.question(String text) {
    return ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessage.answer(
    String text, {
    List<MemoryPhoto> photos = const [],
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.assistant,
      text: text,
      createdAt: DateTime.now(),
      photos: photos,
    );
  }

  bool get isUser => role == ChatRole.user;

  @override
  String toString() => 'ChatMessage(${role.name}: $text, ${photos.length})';
}
