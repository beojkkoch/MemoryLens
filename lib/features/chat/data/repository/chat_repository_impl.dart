import 'package:memorylens/features/chat/data/source/supabase_chat_data_source.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';
import 'package:memorylens/injection_container.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseChatDataSource _dataSource = sl();

  @override
  Future<List<Conversation>> conversations() => _dataSource.conversations();

  @override
  Future<List<ChatMessage>> messages(String conversationId) {
    return _dataSource.messages(conversationId);
  }

  @override
  Future<void> saveMessage(
    String conversationId,
    ChatMessage message, {
    String? title,
  }) {
    return _dataSource.saveMessage(conversationId, message, title: title);
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return _dataSource.deleteConversation(conversationId);
  }
}
