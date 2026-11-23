import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/usecases/answer_question_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/delete_conversation_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/save_chat_message_usecase.dart';
import 'package:memorylens/features/chat/domain/usecases/start_conversation_usecase.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_event.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_state.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/injection_container.dart';

/// The search chat: asks the question, shows «Pensando…» while the assistant
/// answers (HU-20) and keeps every message in the account (HU-25).
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConversations = sl();
  final GetChatMessagesUseCase _getMessages = sl();
  final StartConversationUseCase _startConversation = sl();
  final SaveChatMessageUseCase _saveMessage = sl();
  final AnswerQuestionUseCase _answerQuestion = sl();
  final DeleteConversationUseCase _deleteConversation = sl();

  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatQuestionSent>(_onQuestionSent);
    on<ChatSaveRetried>(_onSaveRetried);
    on<ChatNewConversationRequested>(_onNewConversation);
    on<ChatConversationsRequested>(_onConversationsRequested);
    on<ChatConversationOpened>(_onConversationOpened);
    on<ChatConversationDeleted>(_onConversationDeleted);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatState());
    final List<Conversation> conversations;
    try {
      conversations = await _getConversations();
    } catch (e, stack) {
      addError(e, stack);
      emit(
        ChatState(
          status: ChatStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
      return;
    }
    final id = event.conversationId;
    final Conversation open;
    if (id == null) {
      open = conversations.isEmpty ? _startConversation() : conversations.first;
    } else {
      open =
          conversations.where((c) => c.id == id).firstOrNull ??
          Conversation.draft(id);
    }
    await _open(open, conversations, emit);
  }

  /// Shows a conversation with its messages. An id that is not in the
  /// account is a conversation with no message yet.
  Future<void> _open(
    Conversation open,
    List<Conversation> conversations,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatState(conversation: open, conversations: conversations));
    try {
      final saved = conversations.any((c) => c.id == open.id);
      final messages = saved ? await _getMessages(open.id) : <ChatMessage>[];
      emit(
        ChatState(
          status: ChatStatus.ready,
          conversation: open,
          messages: messages,
          conversations: conversations,
        ),
      );
    } catch (e, stack) {
      addError(e, stack);
      emit(
        ChatState(
          status: ChatStatus.failure,
          conversation: open,
          conversations: conversations,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }

  Future<void> _onQuestionSent(
    ChatQuestionSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    // Nothing is sent empty (CA3), while another answer is on its way (CA5),
    // or while a message waits to be saved, so the order is kept.
    if (text.isEmpty ||
        state.status != ChatStatus.ready ||
        state.thinking ||
        state.pendingSave != null) {
      return;
    }
    final question = ChatMessage.question(text);
    emit(
      state.copyWith(
        messages: [...state.messages, question],
        thinking: true,
        answerError: null,
      ),
    );
    if (!await _persist(question, emit)) return;
    await _answer(question.text, emit);
  }

  Future<void> _onSaveRetried(
    ChatSaveRetried event,
    Emitter<ChatState> emit,
  ) async {
    final pending = state.pendingSave;
    if (pending == null || state.thinking) return;
    emit(state.copyWith(thinking: pending.isUser, pendingSave: null));
    if (!await _persist(pending, emit)) return;
    // The question was not answered yet if it could not even be saved.
    if (pending.isUser) await _answer(pending.text, emit);
  }

  /// Opens an empty conversation. The one that was open is not touched
  /// (HU-23, CA3), and the new one is not in the history until its first
  /// message (CA4).
  void _onNewConversation(
    ChatNewConversationRequested event,
    Emitter<ChatState> emit,
  ) {
    if (!state.canSwitchConversation) return;
    emit(
      state.copyWith(
        conversation: _startConversation(),
        messages: const [],
        answerError: null,
      ),
    );
  }

  /// Brings the list of the panel up to date, because the conversations may
  /// have changed on another device (HU-25, CA2). The latest activity goes
  /// first (HU-24, CA2).
  Future<void> _onConversationsRequested(
    ChatConversationsRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.status == ChatStatus.loading) return;
    try {
      final conversations = await _getConversations();
      emit(state.copyWith(conversations: conversations, listError: null));
    } catch (e, stack) {
      addError(e, stack);
      emit(state.copyWith(listError: AppException.messageFor(e)));
    }
  }

  /// Opens a conversation of the panel with all its messages and photos
  /// (HU-24, CA3).
  Future<void> _onConversationOpened(
    ChatConversationOpened event,
    Emitter<ChatState> emit,
  ) async {
    final target = state.conversations
        .where((c) => c.id == event.conversationId)
        .firstOrNull;
    if (target == null ||
        target.id == state.conversation.id ||
        !state.canSwitchConversation) {
      return;
    }
    await _open(target, state.conversations, emit);
  }

  /// Deletes a conversation after the person confirmed it. When it is the
  /// open one, the latest that is left opens, or an empty one if there is
  /// none (HU-24, CA7). The photos are not deleted (CA8).
  Future<void> _onConversationDeleted(
    ChatConversationDeleted event,
    Emitter<ChatState> emit,
  ) async {
    final id = event.conversationId;
    final isOpen = id == state.conversation.id;
    if (state.status == ChatStatus.loading ||
        (isOpen && !state.canSwitchConversation)) {
      return;
    }
    // Clears the error of an earlier try.
    emit(state.copyWith());
    try {
      await _deleteConversation(id);
    } catch (e, stack) {
      if (e is! AppException || e.technical) addError(e, stack);
      emit(state.copyWith(deleteError: AppException.messageFor(e)));
      return;
    }
    final remaining = [
      for (final c in state.conversations)
        if (c.id != id) c,
    ];
    if (!isOpen) {
      emit(state.copyWith(conversations: remaining));
    } else if (remaining.isEmpty) {
      emit(
        ChatState(
          status: ChatStatus.ready,
          conversation: _startConversation(),
          conversations: remaining,
        ),
      );
    } else {
      await _open(remaining.first, remaining, emit);
    }
  }

  /// Asks the assistant and shows its answer; the answer is saved after it
  /// shows, so a slow save never delays it.
  Future<void> _answer(String question, Emitter<ChatState> emit) async {
    final ChatMessage answer;
    try {
      answer = await _answerQuestion(question);
    } catch (e, stack) {
      if (e is! AppException || e.technical) addError(e, stack);
      emit(
        state.copyWith(
          thinking: false,
          answerError: AppException.messageFor(e),
        ),
      );
      return;
    }
    emit(
      state.copyWith(messages: [...state.messages, answer], thinking: false),
    );
    await _persist(answer, emit);
  }

  /// Saves a message of the open conversation. When it fails the message is
  /// kept to try again and the person is told (HU-25, CA4).
  Future<bool> _persist(ChatMessage message, Emitter<ChatState> emit) async {
    try {
      await _saveMessage(state.conversation.id, message);
    } catch (e, stack) {
      if (e is! AppException || e.technical) addError(e, stack);
      emit(
        state.copyWith(
          thinking: false,
          pendingSave: message,
          saveError: AppException.messageFor(e),
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        conversation: _afterSaving(message),
        conversations: _withOpenFirst(message),
        pendingSave: null,
        saveError: null,
      ),
    );
    return true;
  }

  /// The open conversation takes the name of its first question once it is
  /// saved (HU-23).
  Conversation _afterSaving(ChatMessage message) {
    final open = state.conversation;
    final isNew = !state.conversations.any((c) => c.id == open.id);
    return Conversation(
      id: open.id,
      title: isNew ? Conversation.titleFor(message.text) : open.title,
      updatedAt: DateTime.now(),
    );
  }

  /// The conversation with the latest activity goes first (HU-24, CA2).
  List<Conversation> _withOpenFirst(ChatMessage message) {
    final open = _afterSaving(message);
    return [
      open,
      for (final c in state.conversations)
        if (c.id != open.id) c,
    ];
  }
}
