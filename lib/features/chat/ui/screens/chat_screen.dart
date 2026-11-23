import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/error_message.dart';
import 'package:memorylens/components/error_retry_view.dart';
import 'package:memorylens/components/memory_lens_app_bar.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_bloc.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_event.dart';
import 'package:memorylens/features/chat/ui/bloc/chat_state.dart';
import 'package:memorylens/features/chat/domain/entities/conversation.dart';
import 'package:memorylens/features/chat/ui/widgets/conversations_drawer.dart';
import 'package:memorylens/features/chat/ui/widgets/chat_input_bar.dart';
import 'package:memorylens/features/chat/ui/widgets/message_bubble.dart';
import 'package:memorylens/features/chat/ui/widgets/thinking_bubble.dart';
import 'package:memorylens/theme/app_theme.dart';

/// Chat to find photos with a question in your own words (HU-20). Needs a
/// ChatBloc above it.
///
/// [conversationId] is the address of the conversation to open; with none it
/// opens the latest one, or an empty one.
class ChatScreen extends StatefulWidget {
  final String? conversationId;

  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The chat goes down to the latest message on its own.
  void _scrollToEnd({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.messages.length != current.messages.length ||
          previous.thinking != current.thinking ||
          previous.answerError != current.answerError ||
          current.deleteError != null,
      listener: (context, state) {
        final deleteError = state.deleteError;
        if (deleteError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(deleteError)));
          return;
        }
        _scrollToEnd(animate: state.status == ChatStatus.ready);
      },
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.canvas,
          // Brings the list up to date whenever the panel opens, with the
          // button or by dragging it.
          onEndDrawerChanged: (isOpen) {
            if (isOpen) {
              context.read<ChatBloc>().add(ChatConversationsRequested());
            }
          },
          endDrawer: _drawer(context, state),
          appBar: MemoryLensAppBar(
            title: state.conversation.title,
            onBack: () => Navigator.pop(context),
            actions: [
              IconButton(
                icon: const Icon(Icons.forum_outlined),
                tooltip: 'Conversaciones',
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Nueva conversación',
                onPressed: state.canSwitchConversation
                    ? () => context.read<ChatBloc>().add(
                        ChatNewConversationRequested(),
                      )
                    : null,
              ),
            ],
          ),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _drawer(BuildContext context, ChatState state) {
    final bloc = context.read<ChatBloc>();
    return ConversationsDrawer(
      conversations: state.conversations,
      openId: state.conversation.id,
      canSwitch: state.canSwitchConversation,
      error: state.listError,
      onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
      onNew: () {
        _scaffoldKey.currentState?.closeEndDrawer();
        bloc.add(ChatNewConversationRequested());
      },
      onOpen: (conversation) {
        _scaffoldKey.currentState?.closeEndDrawer();
        bloc.add(ChatConversationOpened(conversation.id));
      },
      onDelete: (conversation) => _confirmDelete(context, state, conversation),
    );
  }

  /// Asks before deleting (HU-24, CA6). The panel stays open to keep going,
  /// unless the open conversation goes, which opens another one.
  Future<void> _confirmDelete(
    BuildContext context,
    ChatState state,
    Conversation conversation,
  ) async {
    final bloc = context.read<ChatBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('¿Eliminar esta búsqueda?'),
        content: Text(
          '«${conversation.title}» se borra de tu cuenta con sus mensajes. '
          'Tus fotos no se borran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || bloc.isClosed) return;
    if (conversation.id == state.conversation.id) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
    bloc.add(ChatConversationDeleted(conversation.id));
  }

  Widget _body(BuildContext context, ChatState state) {
    switch (state.status) {
      case ChatStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ChatStatus.failure:
        return ErrorRetryView(
          message: state.errorMessage ?? 'No pudimos abrir la búsqueda',
          // Tries again with the conversation that failed to open, which may
          // be one of the panel.
          onRetry: () => context.read<ChatBloc>().add(
            ChatStarted(
              state.conversation.id.isEmpty
                  ? widget.conversationId
                  : state.conversation.id,
            ),
          ),
        );
      case ChatStatus.ready:
        return Column(
          children: [
            Expanded(child: _messages(context, state)),
            if (state.pendingSave != null)
              _SaveErrorBar(
                message: state.saveError ?? 'No pudimos guardar tu mensaje',
                onRetry: () => context.read<ChatBloc>().add(ChatSaveRetried()),
              ),
            ChatInputBar(
              busy: state.thinking || state.pendingSave != null,
              onSend: (text) =>
                  context.read<ChatBloc>().add(ChatQuestionSent(text)),
            ),
          ],
        );
    }
  }

  Widget _messages(BuildContext context, ChatState state) {
    final extras = [
      if (state.thinking) const ThinkingBubble(),
      if (state.answerError != null)
        Align(
          alignment: Alignment.centerLeft,
          child: ErrorMessage(message: state.answerError!),
        ),
    ];
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length + extras.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.messages.length) {
          return extras[index - state.messages.length];
        }
        return MessageBubble(
          message: state.messages[index],
          // Pushed on top, so the chat stays where it was (HU-22, CA7).
          onOpenPhoto: (photo) =>
              Navigator.pushNamed(context, '/foto', arguments: photo.id),
        );
      },
    );
  }
}

/// Tells that a message was not saved and lets the person try again
/// (HU-25, CA4).
class _SaveErrorBar extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SaveErrorBar({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      color: AppColors.error.withValues(alpha: 0.08),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
