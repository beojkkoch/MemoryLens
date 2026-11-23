import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/injection_container.dart';

/// The saved conversations for the panel, the latest activity first (HU-24,
/// CA2).
class GetConversationsUseCase {
  final ChatRepository _chat = sl();

  Future<List<Conversation>> call() => _chat.conversations();
}
