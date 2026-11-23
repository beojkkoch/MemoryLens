import 'package:flutter/material.dart';

import 'package:memorylens/theme/app_theme.dart';

/// The field to write the question and the button that sends it (HU-20).
///
/// The text lives here, so a failure never takes it away. Enter and the
/// button send it and clear the field (CA2); empty text or only spaces is not
/// sent (CA3), and the button waits while the assistant answers (CA5).
class ChatInputBar extends StatefulWidget {
  static const fieldKey = Key('chat-input');
  static const sendKey = Key('chat-send');

  /// True while the assistant answers or a message waits to be saved.
  final bool busy;
  final ValueChanged<String> onSend;

  const ChatInputBar({super.key, required this.busy, required this.onSend});

  @override
  State<ChatInputBar> createState() {
    return _ChatInputBarState();
  }
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool get _canSend => !widget.busy && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // The button follows what is typed.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (!_canSend) return;
    final text = _controller.text;
    _controller.clear();
    widget.onSend(text);
    // Ready for the next question, like any chat.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: ChatInputBar.fieldKey,
                controller: _controller,
                focusNode: _focus,
                // The cursor is in the field when the chat opens (CA6).
                autofocus: true,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                // Keeps the keyboard open after sending.
                onEditingComplete: () {},
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'Busca una foto…'),
              ),
            ),
            IconButton(
              key: ChatInputBar.sendKey,
              icon: const Icon(Icons.send),
              tooltip: 'Enviar',
              color: AppColors.primary,
              onPressed: _canSend ? _send : null,
            ),
          ],
        ),
      ),
    );
  }
}
