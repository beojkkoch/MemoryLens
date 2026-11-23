import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/chat/domain/entities/chat_message.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/domain/usecases/answer_question_usecase.dart';
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

  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatQuestionSent>(_onQuestionSent);
    on<ChatSaveRetried>(_onSaveRetried);
    on<ChatNewConversationRequested>(_onNewConversation);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatState());
    try {
      final conversations = await _getConversations();
      final id = event.conversationId;
      final Conversation open;
      if (id == null) {
        open = conversations.isEmpty
            ? _startConversation()
            : conversations.first;
      } else {
        open =
            conversations.where((c) => c.id == id).firstOrNull ??
            Conversation.draft(id);
      }
      // An id that is not in the account is a conversation with no message
      // yet.
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
