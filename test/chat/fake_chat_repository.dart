import 'dart:async';

import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/repository/chat_repository.dart';

/// Keeps the conversations the account would have. A conversation that was
/// never saved is not in it, like the real one.
class FakeChatRepository implements ChatRepository {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  var _minutes = 0;

  /// Thrown by [conversations] and [messages] when set.
  Object? error;

  /// Thrown by [saveMessage] when set.
  Object? saveError;

  /// Thrown by [saveMessage] for the answers of the assistant only, when set.
  Object? answerSaveError;

  /// Thrown by [deleteConversation] when set.
  Object? deleteError;

  /// When set, [saveMessage] waits for it.
  Completer<void>? saveGate;

  /// Every save, as (conversation id, message, title).
  final List<(String, ChatMessage, String?)> saves = [];

  /// The ids of the deleted conversations.
  final List<String> deleted = [];

  /// How many times the list was asked for.
  var listed = 0;

  /// Puts a saved conversation in the account, each one later than the last.
  Conversation seed(
    String id,
    String title, [
    List<ChatMessage> messages = const [],
  ]) {
    final conversation = Conversation(id: id, title: title, updatedAt: _tick());
    _conversations[id] = conversation;
    _messages[id] = [...messages];
    return conversation;
  }

  /// The messages the account holds for a conversation.
  List<ChatMessage> savedMessages(String id) => _messages[id] ?? const [];

  bool isSaved(String id) => _conversations.containsKey(id);

  DateTime _tick() => DateTime(2024, 6, 1).add(Duration(minutes: ++_minutes));

  @override
  Future<List<Conversation>> conversations() async {
    listed++;
    if (error != null) throw error!;
    final list = _conversations.values.toList()
      ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    return list;
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    if (error != null) throw error!;
    return [...?_messages[conversationId]];
  }

  @override
  Future<void> saveMessage(
    String conversationId,
    ChatMessage message, {
    String? title,
  }) async {
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    if (!message.isUser && answerSaveError != null) throw answerSaveError!;
    saves.add((conversationId, message, title));
    final before = _conversations[conversationId];
    _conversations[conversationId] = Conversation(
      id: conversationId,
      title: before?.title ?? title ?? Conversation.defaultTitle,
      updatedAt: _tick(),
    );
    (_messages[conversationId] ??= []).add(message);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(conversationId);
    _conversations.remove(conversationId);
    _messages.remove(conversationId);
  }
}
